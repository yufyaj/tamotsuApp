const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognito = new AWS.CognitoIdentityServiceProvider();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const httpMethod = event.httpMethod;

    switch(httpMethod) {
        case 'GET':
            return handleGetRequest(event);
        case 'PUT':
            return handlePutRequest(event);
        case 'OPTIONS':
            return successResponse({});
        default:
            return errorResponse('Method Not Allowed', 405);
    }
};

async function handleGetRequest(event) {
    // GET request handling (if needed)
}

async function handlePutRequest(event) {
    const token = event.headers.Authorization.split(' ')[1];
    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    let connection;

    try {
        // Cognitoから栄養士情報を取得
        const user = await cognito.getUser({ AccessToken: token }).promise();
        const nutritionistId = user.UserAttributes.find(attr => attr.Name === 'custom:nutritionistId').Value;

        // リクエストボディをパース
        const profileData = JSON.parse(event.body);

        // S3にプロフィール画像をアップロード
        let profileImageUrl = null;
        if (profileData.profileImage) {
            const buffer = Buffer.from(profileData.profileImage, 'base64');
            const key = `nutritionist-profile-images/${nutritionistId}-${Date.now()}.jpg`;
            await s3.putObject({
                Bucket: process.env.S3_BUCKET_NAME,
                Key: key,
                Body: buffer,
                ContentType: 'image/jpeg'
            }).promise();
            profileImageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/${key}`;
        }

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        // トランザクション開始
        await connection.beginTransaction();

        // 栄養士プロフィールを更新
        const updateQuery = `
            UPDATE nutritionists 
            SET 
                name = ?,
                qualifications = ?,
                introduce = ?,
                profile_image_url = ?,
                specialties = ?,
                available_hours = ?
            WHERE nutritionist_id = ?
        `;

        await connection.execute(updateQuery, [
            profileData.name,
            JSON.stringify(profileData.qualifications),
            profileData.introduce,
            profileImageUrl,
            JSON.stringify(profileData.specialties),
            JSON.stringify(profileData.availableHours),
            nutritionistId
        ]);

        // トランザクションをコミット
        await connection.commit();

        // 更新後のプロフィールを取得
        const [updatedProfile] = await connection.execute('SELECT * FROM nutritionists WHERE nutritionist_id = ?', [nutritionistId]);

        return successResponse({ message: '栄養士プロフィールが更新されました', profile: updatedProfile[0] });
    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();
        return errorResponse('栄養士プロフィールの更新に失敗しました');
    } finally {
        if (connection) await connection.end();
    }
}
