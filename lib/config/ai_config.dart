/// Runtime settings for the mobile assistant.
///
/// Keep provider API keys on the web/server side in `.env.local`.
/// The app should call the web assistant endpoint after deployment.
class AiConfig {
  AiConfig._();

  /// Set this to the deployed web route after the web project is hosted.
  ///
  /// Example: https://your-domain.com/api/assistant/chat
  static const String assistantEndpoint = 'https://kuet-cse-automation-web-portal.vercel.app/api/assistant/chat';
}
