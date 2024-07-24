const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();
const ses = new AWS.SES();

exports.handler = async (event) => {
    const { username, email, password } = JSON.parse(event.body);
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;
    
    // カスタム検証コードの生成
    const verificationCode = Math.random().toString(36).substring(2, 8);

    const params = {
        ClientId: clientId,
        Username: username,
        Password: password,
        UserAttributes: [
            {
                Name: 'email',
                Value: email
            }, {
                Name: 'custom:verificationCode', 
                Value: verificationCode
            }
        ]
    };

    try {
        const result = await cognito.signUp(params).promise();
        console.log('User signed up successfully:', result);


    } catch (error) {
        console.error('Error signing up user:', error);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Origin": "*", // 本番環境では特定のオリジンに制限することをお勧めします
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
            },
            body: JSON.stringify({ message: 'Error signing up user', error: error.message })
        };
    }

    try{
        // カスタム検証メールの送信
        await ses.sendEmail({
            Destination: { ToAddresses: [email] },
            Message: {
                Body: { Text: { Data: `TAMOTSUへご登録頂きありがとうございます。\nhttps://api.tamotsu-app.com/user/confirm?email=${email}&code=${verificationCode}` } },
                Subject: { Data: 'TAMOTSUへご登録ありがとうございます' }
            },
            Source: process.env.FROM_EMAIL_ADDRESS
        }).promise();

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*", // 本番環境では特定のオリジンに制限することをお勧めします
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
            },
            body: JSON.stringify({ message: 'User signed up successfully'})
        };
    } catch (error) {
        console.error('Error send mail:', error);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Origin": "*", // 本番環境では特定のオリジンに制限することをお勧めします
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
            },
            body: JSON.stringify({ message: 'Error send mail', error: error.message })
        };
    }
};
