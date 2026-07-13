/// Viratham dates for 2026 — timing-correct (Nithra-style).
///
/// Moon (அமாவாசை / பௌர்ணமி): mark a day if the tithi is present at sunset,
/// begins that calendar day, OR is present at sunrise and continues past noon
/// (drops short morning-only remnants like Aug 28 / Sep 11).
/// Other tithi virathams: last sunrise day per occurrence.
/// சிவராத்திரி: day தேய்பிறை சதுர்த்தசி begins (after பின்பு).
/// Nakshatra days: present in sunrise nakshatra text.
library;


const amavasai2026 = {
  '2026-01-17',
  '2026-02-16',
  '2026-02-17',
  '2026-03-18',
  '2026-04-16',
  '2026-04-17',
  '2026-05-15',
  '2026-06-14',
  '2026-07-13',
  '2026-07-14',
  '2026-08-11',
  '2026-08-12',
  '2026-09-10',
  '2026-10-09',
  '2026-10-10',
  '2026-11-08',
  '2026-11-09',
  '2026-12-07',
  '2026-12-08',
};


const pournami2026 = {
  '2026-01-02',
  '2026-01-03',
  '2026-01-31',
  '2026-03-02',
  '2026-03-03',
  '2026-04-01',
  '2026-04-30',
  '2026-05-01',
  '2026-05-30',
  '2026-05-31',
  '2026-06-28',
  '2026-07-28',
  '2026-07-29',
  '2026-08-27',
  '2026-09-25',
  '2026-09-26',
  '2026-10-25',
  '2026-11-23',
  '2026-11-24',
  '2026-12-23',
};


const ekadasi2026 = {
  '2026-01-14',
  '2026-01-29',
  '2026-02-13',
  '2026-02-27',
  '2026-03-15',
  '2026-03-29',
  '2026-04-12',
  '2026-04-27',
  '2026-05-13',
  '2026-05-27',
  '2026-06-11',
  '2026-06-25',
  '2026-07-10',
  '2026-07-25',
  '2026-08-09',
  '2026-08-22',
  '2026-09-07',
  '2026-09-22',
  '2026-10-05',
  '2026-10-22',
  '2026-11-05',
  '2026-11-21',
  '2026-12-04',
  '2026-12-20',
};


const sashti2026 = {
  '2026-01-09',
  '2026-01-23',
  '2026-02-06',
  '2026-02-23',
  '2026-03-09',
  '2026-03-24',
  '2026-04-08',
  '2026-04-22',
  '2026-05-08',
  '2026-05-22',
  '2026-06-05',
  '2026-06-20',
  '2026-07-06',
  '2026-07-18',
  '2026-08-04',
  '2026-08-18',
  '2026-09-02',
  '2026-09-17',
  '2026-10-02',
  '2026-10-15',
  '2026-10-31',
  '2026-11-14',
  '2026-11-28',
  '2026-12-15',
  '2026-12-29',
};


const pradosham2026 = {
  '2026-01-01',
  '2026-01-16',
  '2026-01-31',
  '2026-02-15',
  '2026-03-01',
  '2026-03-17',
  '2026-03-31',
  '2026-04-15',
  '2026-04-29',
  '2026-05-15',
  '2026-05-29',
  '2026-06-13',
  '2026-06-26',
  '2026-07-12',
  '2026-07-27',
  '2026-08-10',
  '2026-08-26',
  '2026-09-09',
  '2026-09-24',
  '2026-10-08',
  '2026-10-24',
  '2026-11-07',
  '2026-11-21',
  '2026-12-05',
  '2026-12-22',
};


const sivaratri2026 = {
  '2026-01-16',
  '2026-02-15',
  '2026-03-17',
  '2026-04-15',
  '2026-05-15',
  '2026-06-13',
  '2026-07-12',
  '2026-08-10',
  '2026-09-09',
  '2026-10-08',
  '2026-11-07',
  '2026-12-06',
};


const chaturthi2026 = {
  '2026-01-21',
  '2026-02-21',
  '2026-03-22',
  '2026-04-20',
  '2026-05-20',
  '2026-06-18',
  '2026-07-17',
  '2026-08-16',
  '2026-09-15',
  '2026-10-13',
  '2026-11-13',
  '2026-12-13',
};


const sankatahara2026 = {
  '2026-01-07',
  '2026-02-04',
  '2026-03-07',
  '2026-04-06',
  '2026-05-06',
  '2026-06-04',
  '2026-07-04',
  '2026-08-02',
  '2026-09-01',
  '2026-09-30',
  '2026-10-29',
  '2026-11-28',
  '2026-12-27',
};


const kiruthigai2026 = {
  '2026-01-28',
  '2026-02-24',
  '2026-03-23',
  '2026-05-17',
  '2026-06-13',
  '2026-07-11',
  '2026-08-07',
  '2026-09-03',
  '2026-10-01',
  '2026-10-28',
  '2026-11-24',
  '2026-12-22',
};


const thiruvonam2026 = {
  '2026-01-20',
  '2026-02-16',
  '2026-03-15',
  '2026-04-12',
  '2026-05-09',
  '2026-06-05',
  '2026-06-06',
  '2026-07-03',
  '2026-07-30',
  '2026-08-26',
  '2026-09-23',
  '2026-10-20',
  '2026-11-16',
  '2026-12-13',
  '2026-12-14',
};



bool _has(Set<String> s, String dateKey) => s.contains(dateKey);

bool isAmavasaiDate(String dateKey) => _has(amavasai2026, dateKey);
bool isPournamiDate(String dateKey) => _has(pournami2026, dateKey);
bool isEkadasiDate(String dateKey) => _has(ekadasi2026, dateKey);
bool isSashtiDate(String dateKey) => _has(sashti2026, dateKey);
bool isPradoshamDate(String dateKey) => _has(pradosham2026, dateKey);
bool isSivaratriDate(String dateKey) => _has(sivaratri2026, dateKey);
bool isChaturthiDate(String dateKey) => _has(chaturthi2026, dateKey);
bool isSankataharaDate(String dateKey) => _has(sankatahara2026, dateKey);
bool isKiruthigaiDate(String dateKey) => _has(kiruthigai2026, dateKey);
bool isThiruvonamDate(String dateKey) => _has(thiruvonam2026, dateKey);

String sunriseTithiText(String tithiText) {
  final idx = tithiText.indexOf('பின்பு');
  if (idx < 0) return tithiText.trim();
  return tithiText.substring(0, idx).trim();
}

String afterPinbuText(String tithiText) {
  final idx = tithiText.indexOf('பின்பு');
  if (idx < 0) return '';
  return tithiText.substring(idx + 'பின்பு'.length).trim();
}

bool dayHasAmavasai(String tithiText) => tithiText.contains('அமாவாசை');
bool dayHasPournami(String tithiText) =>
    tithiText.contains('பௌர்ணமி') || tithiText.contains('பவுர்ணமி');
bool dayHasEkadasi(String tithiText) => tithiText.contains('ஏகாதசி');
bool dayHasSashti(String tithiText) => tithiText.contains('சஷ்டி');
bool dayHasPradosham(String tithiText) => tithiText.contains('திரயோதசி');
bool dayHasKiruthigai(String nakText) => nakText.contains('கிருத்திகை');
bool dayHasThiruvonam(String nakText) => nakText.contains('திருவோணம்');

final _chaturthiRe = RegExp(r'சதுர்த்தி(?!சி)');

bool dayHasChaturthi(String tithiText) {
  for (final part in tithiText.split('பின்பு')) {
    if (_chaturthiRe.hasMatch(part) && part.contains('வளர்பிறை')) return true;
  }
  return false;
}

bool dayHasSankatahara(String tithiText) {
  for (final part in tithiText.split('பின்பு')) {
    if (_chaturthiRe.hasMatch(part) && part.contains('தேய்பிறை')) return true;
  }
  return false;
}

bool dayHasSivaratri(String tithiText) {
  final aft = afterPinbuText(tithiText);
  if (aft.isNotEmpty) {
    return aft.contains('சதுர்த்தசி') && aft.contains('தேய்பிறை');
  }
  return tithiText.contains('சதுர்த்தசி') && tithiText.contains('தேய்பிறை');
}
