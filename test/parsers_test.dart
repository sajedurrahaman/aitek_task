import 'package:aitek_task/core/storage/key_value_store.dart';
import 'package:aitek_task/core/storage/session_store.dart';
import 'package:aitek_task/features/auth/domain/auth_session.dart';
import 'package:aitek_task/features/auth/domain/credential_rules.dart';
import 'package:aitek_task/features/profile/domain/account_profile.dart';
import 'package:aitek_task/features/promo/domain/promo_material.dart';
import 'package:aitek_task/features/signals/domain/trading_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login rules reject empty and non-numeric values', () {
    expect(CredentialRules.validateLogin(''), 'Enter your account login.');
    expect(
      CredentialRules.validateLogin('abc'),
      'Login should contain digits only.',
    );
    expect(CredentialRules.validatePassword(''), 'Enter your password.');
    expect(CredentialRules.parseLogin('20234561'), 20234561);
    expect(CredentialRules.validatePassword('ladevi31'), isNull);
  });

  test('peanut auth parser accepts the documented token payload', () {
    final parsed = ParsedPeanutAuth.tryParse({
      'result': true,
      'token': 'abc123',
    });
    expect(parsed?.isSuccess, isTrue);
    expect(
      ParsedPeanutAuth.tryParse({'result': false, 'token': ''})?.isSuccess,
      isFalse,
    );
  });

  test('partner token parser accepts a raw string and an object', () {
    expect(parsePartnerToken('partner-token'), 'partner-token');
    expect(parsePartnerToken({'token': 'from-map'}), 'from-map');
  });

  test('account parser reads the peanut sample shape', () {
    final profile = AccountProfile.tryParse({
      'name': 'Test Account',
      'address': 'Street 1',
      'city': 'Dhaka',
      'country': 'Bangladesh',
      'currency': 0,
      'balance': 2796.24,
      'equity': 2800,
      'freeMargin': 2700.5,
      'leverage': 150,
      'currentTradesCount': 1,
      'currentTradesVolume': 0.2,
      'totalTradesCount': 12,
      'totalTradesVolume': 3.6,
      'isAnyOpenTrades': true,
      'isSwapFree': false,
      'type': 1,
      'verificationLevel': 0,
      'zipCode': '1205',
    });
    expect(profile?.name, 'Test Account');
    expect(profile?.currencyLabel, 'USD');
    expect(profile?.balance, 2796.24);
    expect(profile?.leverage, 150);
    expect(profile?.isSwapFree, isFalse);
  });

  test('phone parser keeps the masked cabinet value', () {
    expect(parsePhoneBody('********0000'), '********0000');
  });

  test('signals parser and request uri follow the assignment example', () {
    final signals = parseSignals([
      {
        'Id': 9,
        'Symbol': 'EURUSD',
        'Cmd': 0,
        'OpenPrice': 1.0852,
        'Tp': 1.09,
        'Sl': 1.08,
        'OpenTime': 1479860023,
        'Period': 'H1',
        'Comment': 'Breakout',
      },
    ]);
    expect(signals, hasLength(1));
    expect(signals.single.pair, 'EURUSD');
    expect(signals.single.direction, 'Buy');
    expect(signals.single.price, 1.0852);
    expect(signals.single.period, 'H1');

    final uri = buildSignalsUri(
      login: 20234561,
      pairs: const ['EURUSD', 'GBPUSD'],
      from: DateTime.fromMillisecondsSinceEpoch(1479860023 * 1000, isUtc: true),
      to: DateTime.fromMillisecondsSinceEpoch(1480066860 * 1000, isUtc: true),
    );
    expect(uri.path, endsWith('/GetAnalyticSignals/20234561'));
    expect(uri.queryParameters['tradingsystem'], '3');
    expect(uri.queryParameters['pairs'], 'EURUSD,GBPUSD');
    expect(uri.queryParameters['from'], '1479860023');
    expect(uri.queryParameters['to'], '1480066860');
  });

  test('promo parser reads the JSON string returned inside GetCCPromo', () {
    const xml = '''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <GetCCPromoResponse xmlns="http://tempuri.org/">
      <GetCCPromoResult>{"ferrari": {"image": "https://forex-images.instaforex.com/company_news/userfiles/ferrari.png","text": "Win a Ferrari","link": "https://www.instaforex.com/en/ferrari?x=mobcab","button_text": "I want to win","euro_available": False,"die_date": 0}}</GetCCPromoResult>
    </GetCCPromoResponse>
  </s:Body>
</s:Envelope>
''';
    final item = parsePromoEnvelope(xml).items.single;
    expect(item.title, 'Ferrari');
    expect(item.description, 'Win a Ferrari');
    expect(item.actionLabel, 'I want to win');
    expect(
      item.imageUrl,
      'https://forex-images.ifxdb.com/company_news/userfiles/ferrari.png',
    );
    expect(item.link, 'https://www.instaforex.com/en/ferrari?x=mobcab');
  });

  test('promo parser rewrites the legacy image host and reads cards', () {
    const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <GetCCPromoResponse xmlns="http://tempuri.org/">
      <GetCCPromoResult>
        <CCPromo>
          <Title>Welcome bonus</Title>
          <Description>Open an account</Description>
          <Image>http://forex-images.instaforex.com/banner/a.png</Image>
          <Link>https://www.ifxdb.com/promo</Link>
        </CCPromo>
      </GetCCPromoResult>
    </GetCCPromoResponse>
  </s:Body>
</s:Envelope>
''';
    final envelope = parsePromoEnvelope(xml);
    expect(envelope.hasFault, isFalse);
    expect(envelope.items.single.title, 'Welcome bonus');
    expect(
      envelope.items.single.imageUrl,
      'https://forex-images.ifxdb.com/banner/a.png',
    );
    expect(envelope.items.single.link, 'https://www.ifxdb.com/promo');
  });

  test('promo parser surfaces a soap fault', () {
    const xml = '''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <s:Fault>
      <faultstring>Action not supported</faultstring>
    </s:Fault>
  </s:Body>
</s:Envelope>
''';
    expect(parsePromoEnvelope(xml).fault, contains('Action not supported'));
  });

  test('session store round-trips and clears the cabinet session', () async {
    final store = SessionStore(_MemoryStore());
    const session = AuthSession(
      login: 20234561,
      peanutToken: 'peanut',
      partnerToken: 'partner',
    );
    expect(await store.read(), isNull);
    await store.save(session);
    expect(await store.read(), session);
    await store.clear();
    expect(await store.read(), isNull);
  });
}

class _MemoryStore implements KeyValueStore {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
