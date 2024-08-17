const { CognitoIdentityProviderClient, GetUserCommand } = require("@aws-sdk/client-cognito-identity-provider");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.MY_REGION });
const s3Client = new S3Client({ region: process.env.MY_REGION });

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
    // GET request handling (if needed)
}

async function handlePutRequest(event) {
    const token = event.headers.Authorization.split(' ')[1];
    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    console.log("debug_log_0: start");

    let connection;

    try {
        // Cognitoからユーザー情報を取得
        const getUserCommand = new GetUserCommand({ AccessToken: token });
        const user = await cognitoClient.send(getUserCommand);
        const userId = user.UserAttributes.find(attr => attr.Name === 'custom:userId').Value;

        console.log("debug_log_1: checked cognito user");

        // リクエストボディをパース
        const profileData = JSON.parse(event.body);

        // S3にプロフィール画像をアップロード
        let profileImageUrl = null;
        if (profileData.profileImage) {
            const buffer = Buffer.from(profileData.profileImage, 'base64');
            const key = `profile-images/${userId}-${Date.now()}.jpg`;
            const putObjectCommand = new PutObjectCommand({
                Bucket: process.env.S3_BUCKET_NAME,
                Key: key,
                Body: buffer,
                ContentType: 'image/jpeg'
            });
            await s3Client.send(putObjectCommand);
            profileImageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/${key}`;
            console.log("debug_log_(2): uploaded image");
        }

        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log("debug_log_2: connected db");

        // トランザクション開始
        await connection.beginTransaction();

        console.log("debug_log_3: begin transaction");

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

        console.log("debug_log_4: updated user data");

        // トランザクションをコミット
        await connection.commit();

        // 更新後のプロフィールを取得
        const [updatedProfile] = await connection.execute('SELECT * FROM users WHERE user_id = ?', [userId]);

        console.log("debug_log_5: selected user data");

        return successResponse({ message: 'プロフィールが更新されました', profile: updatedProfile[0] });
    } catch (error) {
        console.error('Error:', error);
        if (connection) await connection.rollback();
        return errorResponse('プロフィールの更新に失敗しました');
    } finally {
        if (connection) await connection.end();
    }
}