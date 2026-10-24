/// Live endpoints from the assignment, plus the values confirmed in the
/// Peanut OpenAPI document.
class ApiConfig {
  const ApiConfig._();

  static const peanutAuth =
      'https://peanut.ifxdb.com/api/ClientCabinetBasic/IsAccountCredentialsCorrect';
  static const peanutAccount =
      'https://peanut.ifxdb.com/api/ClientCabinetBasic/GetAccountInformation';
  static const peanutPhone =
      'https://peanut.ifxdb.com/api/ClientCabinetBasic/GetLastFourNumbersPhone';

  /// The path spelling `Moblie` is the live route from the assignment.
  static const partnerAuth =
      'https://client-api.contentdatapro.com/api/Authentication/RequestMoblieCabinetApiToken';

  static const signalsRoot =
      'https://client-api.contentdatapro.com/clientmobile/GetAnalyticSignals';

  static const promoEndpoint =
      'https://api-forexcopy.contentdatapro.com/Services/CabinetMicroService.svc';

  static const tradingSystem = 3;
  static const promoLanguage = 'en';

  static const legacyImageHost = 'forex-images.instaforex.com';
  static const imageHost = 'forex-images.ifxdb.com';

  static const demoLogin = '20234561';
  static const demoPassword = 'ladevi31';

  static const currencyPairs = <String>[
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'USDCHF',
    'USDCAD',
    'AUDUSD',
    'NZDUSD',
  ];
}
