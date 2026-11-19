class AppConfig {
  // LiveKit Cloud: wss://PROJE_ADI.livekit.cloud
  // Adim 2'de aldigin adresi buraya yaz
  static const String livekitUrl = 'wss://xxxx.livekit.cloud';

  // Render'da kurdugun token sunucusu (Adim 3)
  // Ornek: https://sesli-oda-token.onrender.com/token
  static const String tokenEndpoint = 'https://TOKEN-SUNUCUN.onrender.com/token';

  static const List<String> demoRooms = [
    'Sohbet Odası',
    'Müzik Keyfi',
    'Oyun Arkadaşları',
    'Gece Sohbeti',
  ];
}
