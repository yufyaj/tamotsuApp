const AWS = require('aws-sdk');
const { formatResponse, successResponse, errorResponse } = require('response-utils');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    // HTTPメソッドを取得
    const httpMethod = event.httpMethod;

    switch(httpMethod) {
        case 'GET':
            return handleGetRequest(event);
        case 'POST':
            return handlePostRequest(event);
        case 'OPTION':
            return successResponse({});
        default:
            return errorResponse('Method Not Allowed', 405);
    }
};

async function handleGetRequest(event) {
    // GETリクエストの処理
    const { verificationCode, email } = event.queryStringParameters;

    if (!verificationCode || !email) {
        return errorResponse('検証コードとメールアドレスが必要です。', 400);
    }

    // Cognitoでメールアドレスが未登録であることを確認
    try {
        await cognito.adminGetUser({
            UserPoolId: process.env.COGNITO_USER_POOL_ID,
            Username: email
        }).promise();
        return errorResponse('このメールアドレスは既に登録されています。', 400);
    } catch (error) {
        if (error.code !== 'UserNotFoundException') {
            throw error;
        }
    }

    // DynamoDBで仮登録情報を確認
    const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        KeyConditionExpression: "PK = :pk",
        FilterExpression: "#type = :type",
        ExpressionAttributeNames: {
            "#type": "Type"
        },
        ExpressionAttributeValues: {
            ":pk": `EMAIL#${email}`,
            ":type": "TEMP_USER"
        }
    };

    try {
        const result = await dynamoDB.query(params).promise();
        console.log('DynamoDB result:', JSON.stringify(result, null, 2));
        if (result.Items.length === 0) {
            return errorResponse('アイテムが見つかりません。', 400);
        }

        let isVerified = false;
        result.Items.forEach(item => {
            if (item.Data && item.Data.verification_code  === verificationCode) {
                isVerified = true;
            }
        });
        if (!isVerified) {
            return errorResponse('無効な検証コードです。', 400);
        }
    } catch (error) {
        console.error('DynamoDB error:', error);
        return errorResponse('内部サーバーエラー', 500);
    }

    // リダイレクト用のURLを生成
    const redirectUrl = `https://tamotsu-app.com/verify?email=${encodeURIComponent(email)}&verificationCode=${encodeURIComponent(verificationCode)}`;

    return formatResponse(302, {}, {'Location': redirectUrl});
}

async function handlePostRequest(event) {
    // POSTリクエストの処理（新しい実装）
    const { email, verificationCode } = JSON.parse(event.body);

    if (!email || !verificationCode) {
        return errorResponse('メールアドレスと検証コードが必要です。', 400);
    }

    // ここでDynamoDBでverificationCodeを確認する処理を実装
    // 例：
    const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: { email: email }
    };

    try {
        const result = await dynamoDB.get(params).promise();
        if (!result.Item || result.Item.verificationCode !== verificationCode) {
            return errorResponse('無効な検証コードです。', 400);
        }

        // 検証成功の処理
        return successResponse({ message: 'メールアドレスが確認されました。' });
    } catch (error) {
        console.error('DynamoDB error:', error);
        return errorResponse('内部サーバーエラー');
    }
}
