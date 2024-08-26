const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { v4: uuidv4 } = require('uuid');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');
const { deliveryContent } = require('delivery-content');
const mysql = require('mysql2/promise');

const s3Client = new S3Client({ region: process.env.MY_REGION });

exports.handler = async (event) => {
    const httpMethod = event.httpMethod;

    switch(httpMethod) {
        case 'POST':
            return handlePostRequest(event);
        case 'OPTIONS':
            return successResponse({});
        default:
            return errorResponse('Method Not Allowed', 405);
    }
}

async function handlePostRequest(event) {
    console.log("debug_log_0: start");

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId, nutritionistId } = await verifyAccessToken(token);
    if (!result) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    const senderId = userId ?? nutritionistId;

    console.log("debug_log_1: verified token");
    console.log('Received event:', JSON.stringify(event, null, 2));

    const body = JSON.parse(event.body);
    const imageData = body.image; // Base64エンコードされた画像データ
    const chatId    = body.chat_id; // ユーザーIDなどの追加情報
    const contentType = 'image';
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

    try {
        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        /* チャットIDの存在チェック */
        const [chatRows] = await connection.execute("SELECT * FROM chats WHERE status = 'active' AND (user_id = ? OR nutritionist_id = ?) AND chat_id = ?", [senderId, senderId, chatId]);
        if (chatRows.length == 0) {
            return errorResponse('failed user request');
        }

        // メッセージを配信
        var receiverIds = [];
        chatRows.forEach(row => {
            if (row.user_id         && row.user_id !== senderId)         receiverIds.push(row.user_id);
            if (row.nutritionist_id && row.nutritionist_id !== senderId) receiverIds.push(row.nutritionist_id);
        });

        // 画像データをデコード
        const buffer = Buffer.from(imageData, 'base64');
        const fileName = `${chatId}_${uuidv4()}.jpg`; // ユーザーIDに基づくファイル名

        console.log("debug_log_2: decoded image");

        const putObjectCommand = new PutObjectCommand({
            Bucket: process.env.S3_BUCKET_NAME, // 環境変数からバケット名を取得
            Key: `images/chat/${fileName}`,
            Body: buffer,
            ContentType: 'image/jpeg'
        });

        // S3に画像をアップロード
        await s3Client.send(putObjectCommand);
        console.log(`Successfully uploaded image to ${fileName}`);

        // 送信内容をデータベースに保存
        await connection.execute(
            'INSERT INTO chat_messages (chat_id, timestamp, sender_id, content, content_type, created_at) VALUES (?, ?, ?, ?, ?, ?)',
            [chatId, now, senderId, fileName, contentType, now]
        );

        // connectionIdを取得しあれば配信
        deliveryContent(connection, receiverIds, { chatId, content: fileName, contentType, sendedAt: now });

        return successResponse({
            message: 'Image uploaded successfully',
            fileName: fileName,
            sendedAt: now,
        });
    } catch (error) {
        console.error('Error uploading image:', error);
        return errorResponse('Failed to upload image', 500);
    }
};
