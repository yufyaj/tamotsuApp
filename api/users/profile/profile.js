const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');
const { verifyAccessToken } = require('token-handler');
const { getBase64Image } = require('image-utils');

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
    console.log("debug_log_0: start");

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId } = await verifyAccessToken(token);
    if (!result || !userId) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    console.log("debug_log_1: verified token");

    let connection;
    try {
        // データベース接続
        connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        console.log("debug_log_2: connected db");

        const [userRows] = await connection.execute("SELECT * FROM users WHERE user_id = ?", [userId]);
        if (userRows.length == 0) {
            return errorResponse('failed user request');
        }

        console.log("debug_log_3: selected user data");

        const userRow = userRows[0];
        const profileImageUrl = userRow.profile_image_url;
        const key = profileImageUrl != null ? profileImageUrl.split(`https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/`)[1] : null;
        if (profileImageUrl) {
            const response = {
                name: userRow.name,
                age: userRow.age,
                gender: userRow.gender,
                height: userRow.height,
                allergies: userRow.allergies,
                goals: userRow.goals,
                dietary_restrictions: userRow.dietary_restrictions,
                disliked_foods: userRow.disliked_foods,
                health_concerns: userRow.health_concerns,
                profile_image: await getBase64Image(process.env.S3_BUCKET_NAME, key) // 画像をbase64変換して追加
            };
            return successResponse(response);
        } else {
            const response = {
                name: userRow.name,
                age: userRow.age,
                gender: userRow.gender,
                height: userRow.height,
                allergies: userRow.allergies,
                goals: userRow.goals,
                dietary_restrictions: userRow.dietary_restrictions,
                disliked_foods: userRow.disliked_foods,
                health_concerns: userRow.health_concerns,
                profile_image: null
            };
            return successResponse(response);
        }
    } catch (error){
        console.log(error);
        return errorResponse('プロフィールの取得に失敗しました');
    } finally {
        if (connection) await connection.end();
    }
}

async function handlePutRequest(event) {
    console.log("debug_log_0: start");

    const token = event.headers.Authorization.split(' ')[1];
    const { result, userId } = await verifyAccessToken(token);
    if (!result || !userId) {
        return errorResponse('トークン検証に失敗しました', 401);
    }

    console.log("debug_log_1: verified token");

    let connection;

    try {
        // リクエストボディをパース
        const profileData = JSON.parse(event.body);

        // S3にプロフィール画像をアップロード
        let profileImageUrl = null;
        if (profileData.profileImage) {
            const buffer = Buffer.from(profileData.profileImage, 'base64');
            const key = `profile-images/${userId}.jpg`;
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
                allergies = ?,
                goals = ?,
                dietary_restrictions = ?,
                disliked_foods = ?,
                health_concerns = ?,
            WHERE user_id = ?
        `;

        await connection.execute(updateQuery, [
            profileData.name,
            profileData.age,
            profileData.gender,
            profileData.height,
            JSON.stringify(profileData.allergies),
            profileData.goals,
            JSON.stringify(profileData.dietaryRestrictions),
            profileData.dislikedFoods,
            JSON.stringify(profileData.healthConcerns),
            userId
        ]);

        if (profileImageUrl != null) {
            /* プロフィール画像を再指定しない場合、NULLで更新しないために本対応を実施 */
            const updateProfileUrlQuery = `
                UPDATE users 
                SET 
                    profile_image_url = ?
                WHERE user_id = ?
            `;

            await connection.execute(updateProfileUrlQuery, [
                profileImageUrl,
                userId
            ]);
        }

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