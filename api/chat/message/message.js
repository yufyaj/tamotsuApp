const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { deliveryContent } = require('delivery-content');
const { verifyAccessToken } = require('token-handler');

exports.handler = async (event) => {
    console.log('debug_log_0:start');

    console.log('Connect event:', event);
    const body    = JSON.parse(event.body);
    const token   = body.token;
    const chatId  = body.chat_id;
    const content = body.message;
    console.log('token:', token);

    const { result, userId, nutritionistId } = await verifyAccessToken(token);
    console.log(result, userId, nutritionistId);

    if (!result) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    const senderId = (userId !== null) ? userId : nutritionistId;
    const contentType = 'message';
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

    console.log("debug_log_1: verified token");

    // データベース接続
    let connection;
    try {
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log('debug_log_2:connected db');

        /* チャットIDの存在チェック */
        const [chatRows] = await connection.execute("SELECT * FROM chats WHERE status = 'active' AND (user_id = ? OR nutritionist_id = ?) AND chat_id = ?", [senderId, senderId, chatId]);
        if (chatRows.length == 0) {
            return errorResponse('failed user request');
        }

        // 送信内容をデータベースに保存
        await connection.execute(
            'INSERT INTO chat_messages (chat_id, timestamp, sender_id, content, content_type, created_at) VALUES (?, ?, ?, ?, ?, ?)',
            [chatId, now, senderId, content, contentType, now]
        );

        console.log('debug_log_3:inserted db');

        // メッセージを配信
        var receiverIds = [];
        chatRows.forEach(row => {
            if (row.user_id         && row.user_id !== senderId)         receiverIds.push(row.user_id);
            if (row.nutritionist_id && row.nutritionist_id !== senderId) receiverIds.push(row.nutritionist_id);
        });

        // connectionIdを取得しあれば配信
        deliveryContent(connection, receiverIds, { chatId, content, contentType });

        return successResponse({ body: 'Message received', sendedAt: now });
    } catch(error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();
        return errorResponse('An error occurred', 500);
    } finally {
        if (connection) await connection.end();
    }
};