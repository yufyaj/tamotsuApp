const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const ses = new AWS.SES();
const { v4: uuidv4 } = require('uuid');

exports.handler = async (event, context) => {
  const { email, password, name } = JSON.parse(event.body);

  try {
    // Cognito User Poolにユーザーを登録
    const signUpResponse = await cognito.signUp({
      ClientId: process.env.COGNITO_USER_POOL_CLIENT_ID,
      Username: email,
      Password: password,
      UserAttributes: [
        { Name: 'name', Value: name },
        { Name: 'email', Value: email }
      ]
    }).promise();

    const userId = uuidv4(); // UUIDを生成

    // 確認メール送信
    const confirmationUrl = `https://<span class="math-inline">\{process\.env\.API\_GATEWAY\_ID\}\.execute\-api\.</span>{process.env.AWS_REGION}.amazonaws.com/<span class="math-inline">\{process\.env\.API\_GATEWAY\_STAGE\_ID\}/confirm?code\=</span>{signUpResponse.CodeDeliveryDetails.Destination}`;
    await ses.sendTemplatedEmail({
      Source: process.env.FROM_EMAIL_ADDRESS,
      Destination: {
        ToAddresses: [email]
      },
      Template: "confirmation-template",
      TemplateData: JSON.stringify({
        "email_verification_code": signUpResponse.CodeDeliveryDetails.Destination,
        "confirmation_url": confirmationUrl
      }),
      ConfigurationSetName: process.env.CONFIGURATION_SET_NAME // Configuration Setの名前
    }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: '登録が完了しました。確認メールをご確認ください。' })
    };

  } catch (error) {
    console.error('Error:', error);

    if (error.code === 'UsernameExistsException') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'このメールアドレスは既に登録されています。' })
      };
    } else if (error.code === 'InvalidPasswordException') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'パスワードがCognitoの要件を満たしていません。' })
      };
    } else {
      return {
        statusCode: 500,
        body: JSON.stringify({ message: 'エラーが発生しました。' })
      };
    }
  }
};
