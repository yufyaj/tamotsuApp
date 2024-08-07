const AWS = require('aws-sdk');
const { formatResponse, successResponse, errorResponse } = require('response-utils');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    // HTTPメソッドを取得
    const httpMethod = event.httpMethod;

    switch(httpMethod) {
        case 'POST':
            return handlePostRequest(event);
        case 'OPTION':
            return successResponse({});
        default:
            return errorResponse('Method Not Allowed', 405);
    }
};

async function handlePostRequest(event) {
    const { email, verificationCode, password } = JSON.parse(event.body);
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;

    // 入力バリデーション
    if (!email || !verificationCode || !password) {
        return errorResponse('必須フィールドが不足しています');
    }

    try {
        // DynamoDBから一時保存データを取得
        const params = {
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Key: {
                PK: `EMAIL#${email}`,
                SK: `TEMP_USER`,
            }
        };
        const result = await dynamoDB.get(params).promise();
        console.log('DynamoDB result:', JSON.stringify(result, null, 2));
        if (!result.Item) {
            return errorResponse('アイテムが見つかりません。', 400);
        }

        if (result.Item.Data.verification_code !== verificationCode) {
            return errorResponse('無効な検証コードです。', 400);
        }

        // Cognitoにユーザーを登録
        // Cognitoにユーザーを登録
        const signUpParams = {
            ClientId: clientId,
            Username: email,
            Password: password,
            UserAttributes: []
        };
        await cognito.signUp(signUpParams).promise();

        await dynamoDB.delete(params).promise();

        return successResponse({ message: 'ユーザーの登録が完了しました' });
    } catch (error) {
        console.error('Error:', error);
        return errorResponse('サーバーエラーが発生しました');
    }
}
