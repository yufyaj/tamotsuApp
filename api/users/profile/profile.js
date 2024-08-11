const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognito = new AWS.CognitoIdentityServiceProvider();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    // HTTPメソッドを取得
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
}

async function handlePutRequest(event) {
    const token = event.headers.Authorization.split(' ')[1];
    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    let connection;

    try {
        // Cognitoからユーザー情報を取得
        const user = await cognito.getUser({ AccessToken: token }).promise();
        const userId = user.UserAttributes.find(attr => attr.Name === 'custom:userId').Value;

        // リクエストボディをパース
        const profileData = JSON.parse(event.body);

        // S3にプロフィール画像をアップロード
        let profileImageUrl = null;
        if (profileData.profileImage) {
            const buffer = Buffer.from(profileData.profileImage, 'base64');
            const key = `profile-images/${userId}-${Date.now()}.jpg`;
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

        // ユーザープロフィールを更新
        const updateQuery = `
            UPDATE users 
            SET 
                name = ?,
                age = ?,
                gender = ?,
                height = ?,
                weight = ?,
                allergies = ?,
                goal = ?,
                dietary_restrictions = ?,
                disliked_foods = ?,
                health_concerns = ?,
                profile_image_url = ?
            WHERE user_id = ?
        `;

        await connection.execute(updateQuery, [
            profileData.name,
            profileData.age,
            profileData.gender,
            profileData.height,
            profileData.weight,
            JSON.stringify(profileData.allergies),
            profileData.goal,
            JSON.stringify(profileData.dietaryRestrictions),
            profileData.dislikedFoods,
            JSON.stringify(profileData.healthConcerns),
            profileImageUrl,
            userId
        ]);
        
        // プロフィール画像の処理（S3へのアップロードなど）は省略

        // トランザクションをコミット
        await connection.commit();

        // 更新後のプロフィールを取得
        const [updatedProfile] = await connection.execute('SELECT * FROM users WHERE user_id = ?', [userId]);

        return successResponse({ message: 'プロフィールが更新されました', profile: updatedProfile[0] });
    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();
        return errorResponse('プロフィールの更新に失敗しました');
    } finally {
        if (connection) await connection.end();
    }
};
