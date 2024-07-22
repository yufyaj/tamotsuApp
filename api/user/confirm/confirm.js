const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
    // URLパラメータを取得
    const { email, code } = event.queryStringParameters;
    
    if (!email || !code) {
        return {
            statusCode: 400,
            body: JSON.stringify({ message: 'Email and verification code are required' })
        };
    }

    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    try {
        // emailを使用してユーザーを検索
        const listUsersParams = {
            UserPoolId: userPoolId,
            Filter: `email = "${email}"`
        };
        const userList = await cognito.listUsers(listUsersParams).promise();
        
        if (userList.Users.length === 0) {
            return {
                statusCode: 404,
                body: JSON.stringify({ message: 'User not found' })
            };
        }

        const user = userList.Users[0];
        const storedCode = user.Attributes.find(attr => attr.Name === 'custom:verificationCode')?.Value;

        if (code !== storedCode) {
            return {
                statusCode: 400,
                body: JSON.stringify({ message: 'Invalid verification code' })
            };
        }

        // メール検証ステータスを更新
        const updateParams = {
            UserPoolId: userPoolId,
            Username: user.Username,
            UserAttributes: [
                {
                    Name: 'email_verified',
                    Value: 'true'
                }
            ]
        };
        await cognito.adminUpdateUserAttributes(updateParams).promise();
        
        // ユーザーを確認済みに設定
        await cognito.adminConfirmSignUp({
            UserPoolId: userPoolId,
            Username: user.Username
        }).promise();

        // カスタム属性の検証コードを削除（オプション）
        const deleteCodeParams = {
            UserPoolId: userPoolId,
            Username: user.Username,
            UserAttributeNames: ['custom:verificationCode']
        };
        await cognito.adminDeleteUserAttributes(deleteCodeParams).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Email verified successfully' })
        };
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Internal server error' })
        };
    }
};
