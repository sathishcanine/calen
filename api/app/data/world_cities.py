"""Major world cities for Tamil panchangam precompute (lat/lon + IANA timezone).

Not every municipality on Earth — ~180 hubs covering Tamil Nadu, India, diaspora,
and global capitals. Extend this list or import more via seed_cities --json path.
"""

from __future__ import annotations

from typing import NamedTuple


class CitySeed(NamedTuple):
    id: str
    name_en: str
    name_ta: str
    lat: float
    lon: float
    country: str
    timezone: str
    tz_offset: float = 5.5
    is_default: bool = False


def _c(
    id: str,
    name_en: str,
    name_ta: str,
    lat: float,
    lon: float,
    country: str,
    timezone: str,
    tz_offset: float = 5.5,
    is_default: bool = False,
) -> CitySeed:
    return CitySeed(id, name_en, name_ta, lat, lon, country, timezone, tz_offset, is_default)


# fmt: off
WORLD_CITIES: list[CitySeed] = [
    # ── Tamil Nadu & Puducherry ──────────────────────────────────────────────
    _c("chennai", "Chennai", "சென்னை", 13.0827, 80.2707, "IN", "Asia/Kolkata", 5.5, is_default=True),
    _c("coimbatore", "Coimbatore", "கோயம்புத்தூர்", 11.0168, 76.9558, "IN", "Asia/Kolkata"),
    _c("madurai", "Madurai", "மதுரை", 9.9252, 78.1198, "IN", "Asia/Kolkata"),
    _c("tiruchirappalli", "Tiruchirappalli", "திருச்சி", 10.7905, 78.7047, "IN", "Asia/Kolkata"),
    _c("salem", "Salem", "சேலம்", 11.6643, 78.1460, "IN", "Asia/Kolkata"),
    _c("tirunelveli", "Tirunelveli", "திருநெல்வேலி", 8.7139, 77.7567, "IN", "Asia/Kolkata"),
    _c("erode", "Erode", "ஈரோடு", 11.3410, 77.7172, "IN", "Asia/Kolkata"),
    _c("vellore", "Vellore", "வேலூர்", 12.9165, 79.1325, "IN", "Asia/Kolkata"),
    _c("thanjavur", "Thanjavur", "தஞ்சாவூர்", 10.7870, 79.1378, "IN", "Asia/Kolkata"),
    _c("dindigul", "Dindigul", "திண்டுக்கல்", 10.3673, 77.9803, "IN", "Asia/Kolkata"),
    _c("thoothukudi", "Thoothukudi", "தூத்துக்குடி", 8.7642, 78.1348, "IN", "Asia/Kolkata"),
    _c("nagercoil", "Nagercoil", "நாகர்கோவில்", 8.1833, 77.4119, "IN", "Asia/Kolkata"),
    _c("karur", "Karur", "கரூர்", 10.9601, 78.0766, "IN", "Asia/Kolkata"),
    _c("hosur", "Hosur", "ஓசூர்", 12.7409, 77.8253, "IN", "Asia/Kolkata"),
    _c("cuddalore", "Cuddalore", "கடலூர்", 11.7480, 79.7714, "IN", "Asia/Kolkata"),
    _c("kanchipuram", "Kanchipuram", "காஞ்சிபுரம்", 12.8342, 79.7036, "IN", "Asia/Kolkata"),
    _c("tiruppur", "Tiruppur", "திருப்பூர்", 11.1085, 77.3411, "IN", "Asia/Kolkata"),
    _c("namakkal", "Namakkal", "நாமக்கல்", 11.2189, 78.1672, "IN", "Asia/Kolkata"),
    _c("sivakasi", "Sivakasi", "சிவகாசி", 9.4532, 77.8024, "IN", "Asia/Kolkata"),
    _c("nagapattinam", "Nagapattinam", "நாகப்பட்டினம்", 10.7672, 79.8449, "IN", "Asia/Kolkata"),
    _c("ramanathapuram", "Ramanathapuram", "ராமநாதபுரம்", 9.3639, 78.8395, "IN", "Asia/Kolkata"),
    _c("virudhunagar", "Virudhunagar", "விருதுநகர்", 9.5680, 77.9624, "IN", "Asia/Kolkata"),
    _c("theni", "Theni", "தேனி", 10.0104, 77.4768, "IN", "Asia/Kolkata"),
    _c("tiruvannamalai", "Tiruvannamalai", "திருவண்ணாமலை", 12.2253, 79.0747, "IN", "Asia/Kolkata"),
    _c("krishnagiri", "Krishnagiri", "கிருஷ்ணகிரி", 12.5186, 78.2137, "IN", "Asia/Kolkata"),
    _c("dharmapuri", "Dharmapuri", "தர்மபுரி", 12.1211, 78.1582, "IN", "Asia/Kolkata"),
    _c("pudukkottai", "Pudukkottai", "புதுக்கோட்டை", 10.3833, 78.8001, "IN", "Asia/Kolkata"),
    _c("perambalur", "Perambalur", "பெரம்பலூர்", 11.2340, 78.8820, "IN", "Asia/Kolkata"),
    _c("ariyalur", "Ariyalur", "அரியலூர்", 11.1401, 79.0756, "IN", "Asia/Kolkata"),
    _c("mayiladuthurai", "Mayiladuthurai", "மயிலாடுதுறை", 11.1032, 79.6550, "IN", "Asia/Kolkata"),
    _c("tenkasi", "Tenkasi", "தென்காசி", 8.9558, 77.3153, "IN", "Asia/Kolkata"),
    _c("kanyakumari", "Kanyakumari", "கன்னியாகுமரி", 8.0883, 77.5385, "IN", "Asia/Kolkata"),
    _c("nilgiris", "Udhagamandalam", "உதகமண்டலம்", 11.4064, 76.6932, "IN", "Asia/Kolkata"),
    _c("puducherry", "Puducherry", "புதுச்சேரி", 11.9416, 79.8083, "IN", "Asia/Kolkata"),
    _c("karaikal", "Karaikal", "காரைக்கால்", 10.9254, 79.8380, "IN", "Asia/Kolkata"),

    # ── Rest of India ────────────────────────────────────────────────────────
    _c("mumbai", "Mumbai", "மும்பை", 19.0760, 72.8777, "IN", "Asia/Kolkata"),
    _c("delhi", "New Delhi", "புது தில்லி", 28.6139, 77.2090, "IN", "Asia/Kolkata"),
    _c("bangalore", "Bengaluru", "பெங்களூர்", 12.9716, 77.5946, "IN", "Asia/Kolkata"),
    _c("hyderabad", "Hyderabad", "ஹைதராபாத்", 17.3850, 78.4867, "IN", "Asia/Kolkata"),
    _c("kolkata", "Kolkata", "கொல்கத்தா", 22.5726, 88.3639, "IN", "Asia/Kolkata"),
    _c("pune", "Pune", "புனே", 18.5204, 73.8567, "IN", "Asia/Kolkata"),
    _c("ahmedabad", "Ahmedabad", "அகமதாபாத்", 23.0225, 72.5714, "IN", "Asia/Kolkata"),
    _c("jaipur", "Jaipur", "ஜெய்ப்பூர்", 26.9124, 75.7873, "IN", "Asia/Kolkata"),
    _c("lucknow", "Lucknow", "லக்னோ", 26.8467, 80.9462, "IN", "Asia/Kolkata"),
    _c("kanpur", "Kanpur", "கான்பூர்", 26.4499, 80.3319, "IN", "Asia/Kolkata"),
    _c("nagpur", "Nagpur", "நாக்பூர்", 21.1458, 79.0882, "IN", "Asia/Kolkata"),
    _c("indore", "Indore", "இந்தோர்", 22.7196, 75.8577, "IN", "Asia/Kolkata"),
    _c("bhopal", "Bhopal", "போபால்", 23.2599, 77.4126, "IN", "Asia/Kolkata"),
    _c("visakhapatnam", "Visakhapatnam", "விசாகப்பட்டினம்", 17.6868, 83.2185, "IN", "Asia/Kolkata"),
    _c("patna", "Patna", "பாட்னா", 25.5941, 85.1376, "IN", "Asia/Kolkata"),
    _c("vadodara", "Vadodara", "வதோதரா", 22.3072, 73.1812, "IN", "Asia/Kolkata"),
    _c("ludhiana", "Ludhiana", "லுதியானா", 30.9010, 75.8573, "IN", "Asia/Kolkata"),
    _c("agra", "Agra", "ஆக்ரா", 27.1767, 78.0081, "IN", "Asia/Kolkata"),
    _c("nashik", "Nashik", "நாசிக்", 19.9975, 73.7898, "IN", "Asia/Kolkata"),
    _c("varanasi", "Varanasi", "வாரணாசி", 25.3176, 82.9739, "IN", "Asia/Kolkata"),
    _c("amritsar", "Amritsar", "அமிர்தசர்", 31.6340, 74.8723, "IN", "Asia/Kolkata"),
    _c("prayagraj", "Prayagraj", "பிரயாக்ராஜ்", 25.4358, 81.8463, "IN", "Asia/Kolkata"),
    _c("jodhpur", "Jodhpur", "ஜோத்பூர்", 26.2389, 73.0243, "IN", "Asia/Kolkata"),
    _c("guwahati", "Guwahati", "குவஹாத்தி", 26.1445, 91.7362, "IN", "Asia/Kolkata"),
    _c("chandigarh", "Chandigarh", "சண்டிகர்", 30.7333, 76.7794, "IN", "Asia/Kolkata"),
    _c("mysore", "Mysuru", "மைசூர்", 12.2958, 76.6394, "IN", "Asia/Kolkata"),
    _c("ranchi", "Ranchi", "ராஞ்சி", 23.3441, 85.3096, "IN", "Asia/Kolkata"),
    _c("kochi", "Kochi", "கொச்சி", 9.9312, 76.2673, "IN", "Asia/Kolkata"),
    _c("thiruvananthapuram", "Thiruvananthapuram", "திருவனந்தபுரம்", 8.5241, 76.9366, "IN", "Asia/Kolkata"),
    _c("kozhikode", "Kozhikode", "கோழிக்கோடு", 11.2588, 75.7804, "IN", "Asia/Kolkata"),
    _c("mangalore", "Mangaluru", "மங்களூர்", 12.9141, 74.8560, "IN", "Asia/Kolkata"),
    _c("hubli", "Hubballi", "ஹுப்ளி", 15.3647, 75.1240, "IN", "Asia/Kolkata"),
    _c("rajkot", "Rajkot", "ராஜ்கோட்", 22.3039, 70.8022, "IN", "Asia/Kolkata"),
    _c("surat", "Surat", "சூரத்", 21.1702, 72.8311, "IN", "Asia/Kolkata"),
    _c("dehradun", "Dehradun", "டேராடூன்", 30.3165, 78.0322, "IN", "Asia/Kolkata"),
    _c("shimla", "Shimla", "ஷிம்லா", 31.1048, 77.1734, "IN", "Asia/Kolkata"),
    _c("srinagar", "Srinagar", "ஸ்ரீநகர்", 34.0837, 74.7973, "IN", "Asia/Kolkata"),
    _c("imphal", "Imphal", "இம்பால்", 24.8170, 93.9368, "IN", "Asia/Kolkata"),
    _c("itanagar", "Itanagar", "இட்டாநகர்", 27.0844, 93.6053, "IN", "Asia/Kolkata"),
    _c("gangtok", "Gangtok", "காங்டோக்", 27.3389, 88.6065, "IN", "Asia/Kolkata"),
    _c("agartala", "Agartala", "அகர்தலா", 23.8315, 91.2868, "IN", "Asia/Kolkata"),
    _c("shillong", "Shillong", "ஷிலாங்", 25.5788, 91.8933, "IN", "Asia/Kolkata"),
    _c("bhubaneswar", "Bhubaneswar", "புவனேஸ்வர்", 20.2961, 85.8245, "IN", "Asia/Kolkata"),
    _c("raipur", "Raipur", "ராய்ப்பூர்", 21.2514, 81.6296, "IN", "Asia/Kolkata"),
    _c("panaji", "Panaji", "பணாஜி", 15.4909, 73.8278, "IN", "Asia/Kolkata"),
    _c("dwarka", "Dwarka", "துவாரகா", 22.2442, 68.9685, "IN", "Asia/Kolkata"),

    # ── Sri Lanka ────────────────────────────────────────────────────────────
    _c("colombo", "Colombo", "கொழும்பு", 6.9271, 79.8612, "LK", "Asia/Colombo", 5.5),
    _c("jaffna", "Jaffna", "யாழ்ப்பாணம்", 9.6615, 80.0255, "LK", "Asia/Colombo", 5.5),
    _c("kandy", "Kandy", "கண்டி", 7.2906, 80.6337, "LK", "Asia/Colombo", 5.5),
    _c("trincomalee", "Trincomalee", "திருகோணமலை", 8.5874, 81.2152, "LK", "Asia/Colombo", 5.5),
    _c("batticaloa", "Batticaloa", "மட்டக்களப்பு", 7.7102, 81.6924, "LK", "Asia/Colombo", 5.5),

    # ── Southeast Asia ───────────────────────────────────────────────────────
    _c("singapore", "Singapore", "சிங்கப்பூர்", 1.3521, 103.8198, "SG", "Asia/Singapore", 8.0),
    _c("kuala_lumpur", "Kuala Lumpur", "கோலாலம்பூர்", 3.1390, 101.6869, "MY", "Asia/Kuala_Lumpur", 8.0),
    _c("penang", "George Town", "பினாங்கு", 5.4141, 100.3288, "MY", "Asia/Kuala_Lumpur", 8.0),
    _c("ipoh", "Ipoh", "ஈப்போ", 4.5975, 101.0901, "MY", "Asia/Kuala_Lumpur", 8.0),
    _c("johor_bahru", "Johor Bahru", "ஜொஹோர் பாரு", 1.4927, 103.7414, "MY", "Asia/Kuala_Lumpur", 8.0),
    _c("bangkok", "Bangkok", "பாங்காக்", 13.7563, 100.5018, "TH", "Asia/Bangkok", 7.0),
    _c("jakarta", "Jakarta", "ஜகார்த்தா", -6.2088, 106.8456, "ID", "Asia/Jakarta", 7.0),
    _c("manila", "Manila", "மணிலா", 14.5995, 120.9842, "PH", "Asia/Manila", 8.0),
    _c("ho_chi_minh", "Ho Chi Minh City", "ஹோ சி மின்", 10.8231, 106.6297, "VN", "Asia/Ho_Chi_Minh", 7.0),
    _c("yangon", "Yangon", "யாங்கோன்", 16.8661, 96.1951, "MM", "Asia/Yangon", 6.5),

    # ── Gulf & Middle East ───────────────────────────────────────────────────
    _c("dubai", "Dubai", "துபாய்", 25.2048, 55.2708, "AE", "Asia/Dubai", 4.0),
    _c("abu_dhabi", "Abu Dhabi", "அபுதாபி", 24.4539, 54.3773, "AE", "Asia/Dubai", 4.0),
    _c("doha", "Doha", "தோஹா", 25.2854, 51.5310, "QA", "Asia/Qatar", 3.0),
    _c("riyadh", "Riyadh", "ரியாத்", 24.7136, 46.6753, "SA", "Asia/Riyadh", 3.0),
    _c("jeddah", "Jeddah", "ஜெத்தா", 21.4858, 39.1925, "SA", "Asia/Riyadh", 3.0),
    _c("muscat", "Muscat", "மஸ்கட்", 23.5880, 58.3829, "OM", "Asia/Muscat", 4.0),
    _c("kuwait_city", "Kuwait City", "குவைத்", 29.3759, 47.9774, "KW", "Asia/Kuwait", 3.0),
    _c("manama", "Manama", "மனாமா", 26.2285, 50.5860, "BH", "Asia/Bahrain", 3.0),
    _c("tel_aviv", "Tel Aviv", "தெல் அவிவ்", 32.0853, 34.7818, "IL", "Asia/Jerusalem", 2.0),
    _c("istanbul", "Istanbul", "இஸ்தான்புல்", 41.0082, 28.9784, "TR", "Europe/Istanbul", 3.0),

    # ── United States ────────────────────────────────────────────────────────
    _c("new_york", "New York", "நியூயார்க்", 40.7128, -74.0060, "US", "America/New_York", -5.0),
    _c("los_angeles", "Los Angeles", "லாஸ்ஞ்சலஸ்", 34.0522, -118.2437, "US", "America/Los_Angeles", -8.0),
    _c("chicago", "Chicago", "சிகாகோ", 41.8781, -87.6298, "US", "America/Chicago", -6.0),
    _c("houston", "Houston", "ஹூஸ்டன்", 29.7604, -95.3698, "US", "America/Chicago", -6.0),
    _c("san_francisco", "San Francisco", "சான் பிரான்சிஸ்கோ", 37.7749, -122.4194, "US", "America/Los_Angeles", -8.0),
    _c("seattle", "Seattle", "சியாட்டில்", 47.6062, -122.3321, "US", "America/Los_Angeles", -8.0),
    _c("boston", "Boston", "பாஸ்டன்", 42.3601, -71.0589, "US", "America/New_York", -5.0),
    _c("atlanta", "Atlanta", "அட்லாண்டா", 33.7490, -84.3880, "US", "America/New_York", -5.0),
    _c("dallas", "Dallas", "டாலஸ்", 32.7767, -96.7970, "US", "America/Chicago", -6.0),
    _c("washington_dc", "Washington DC", "வாஷிங்டன்", 38.9072, -77.0369, "US", "America/New_York", -5.0),
    _c("newark", "Newark", "நியூவார்க்", 40.7357, -74.1724, "US", "America/New_York", -5.0),
    _c("austin", "Austin", "ஆஸ்டின்", 30.2672, -97.7431, "US", "America/Chicago", -6.0),
    _c("phoenix", "Phoenix", "பீனிக்ஸ்", 33.4484, -112.0740, "US", "America/Phoenix", -7.0),
    _c("denver", "Denver", "டென்வர்", 39.7392, -104.9903, "US", "America/Denver", -7.0),

    # ── Canada ───────────────────────────────────────────────────────────────
    _c("toronto", "Toronto", "டொராண்டோ", 43.6532, -79.3832, "CA", "America/Toronto", -5.0),
    _c("vancouver", "Vancouver", "வான்கூவர்", 49.2827, -123.1207, "CA", "America/Vancouver", -8.0),
    _c("montreal", "Montreal", "மாண்ட்ரீல்", 45.5017, -73.5673, "CA", "America/Toronto", -5.0),
    _c("calgary", "Calgary", "கல்கரி", 51.0447, -114.0719, "CA", "America/Edmonton", -7.0),
    _c("ottawa", "Ottawa", "ஒட்டாவா", 45.4215, -75.6972, "CA", "America/Toronto", -5.0),
    _c("edmonton", "Edmonton", "எட்மாண்டன்", 53.5461, -113.4938, "CA", "America/Edmonton", -7.0),

    # ── United Kingdom & Ireland ─────────────────────────────────────────────
    _c("london", "London", "லண்டன்", 51.5074, -0.1278, "GB", "Europe/London", 0.0),
    _c("manchester", "Manchester", "மான்செஸ்டர்", 53.4808, -2.2426, "GB", "Europe/London", 0.0),
    _c("birmingham", "Birmingham", "பர்மிங்காம்", 52.4862, -1.8904, "GB", "Europe/London", 0.0),
    _c("leicester", "Leicester", "லெய்செஸ்டர்", 52.6369, -1.1398, "GB", "Europe/London", 0.0),
    _c("dublin", "Dublin", "டப்ளின்", 53.3498, -6.2603, "IE", "Europe/Dublin", 0.0),

    # ── Europe ───────────────────────────────────────────────────────────────
    _c("paris", "Paris", "பாரிஸ்", 48.8566, 2.3522, "FR", "Europe/Paris", 1.0),
    _c("berlin", "Berlin", "பெர்லின்", 52.5200, 13.4050, "DE", "Europe/Berlin", 1.0),
    _c("amsterdam", "Amsterdam", "ஆம்ஸ்டர்டாம்", 52.3676, 4.9041, "NL", "Europe/Amsterdam", 1.0),
    _c("zurich", "Zurich", "ஜூரிச்", 47.3769, 8.5417, "CH", "Europe/Zurich", 1.0),
    _c("rome", "Rome", "ரோம்", 41.9028, 12.4964, "IT", "Europe/Rome", 1.0),
    _c("madrid", "Madrid", "மாட்ரிட்", 40.4168, -3.7038, "ES", "Europe/Madrid", 1.0),
    _c("stockholm", "Stockholm", "ஸ்டாக்ஹோம்", 59.3293, 18.0686, "SE", "Europe/Stockholm", 1.0),
    _c("oslo", "Oslo", "ஓஸ்லோ", 59.9139, 10.7522, "NO", "Europe/Oslo", 1.0),
    _c("helsinki", "Helsinki", "ஹெல்சிங்கி", 60.1699, 24.9384, "FI", "Europe/Helsinki", 2.0),
    _c("moscow", "Moscow", "மாஸ்கோ", 55.7558, 37.6173, "RU", "Europe/Moscow", 3.0),
    _c("athens", "Athens", "ஏதென்ஸ்", 37.9838, 23.7275, "GR", "Europe/Athens", 2.0),

    # ── Australia & New Zealand ──────────────────────────────────────────────
    _c("sydney", "Sydney", "சிட்னி", -33.8688, 151.2093, "AU", "Australia/Sydney", 10.0),
    _c("melbourne", "Melbourne", "மெல்போர்ன்", -37.8136, 144.9631, "AU", "Australia/Melbourne", 10.0),
    _c("brisbane", "Brisbane", "பிரிஸ்பேன்", -27.4698, 153.0251, "AU", "Australia/Brisbane", 10.0),
    _c("perth", "Perth", "பெர்த்", -31.9505, 115.8605, "AU", "Australia/Perth", 8.0),
    _c("adelaide", "Adelaide", "அடிலெய்ட்", -34.9285, 138.6007, "AU", "Australia/Adelaide", 9.5),
    _c("auckland", "Auckland", "ஆக்லாந்து", -36.8485, 174.7633, "NZ", "Pacific/Auckland", 12.0),
    _c("wellington", "Wellington", "வெலிங்டன்", -41.2865, 174.7762, "NZ", "Pacific/Auckland", 12.0),

    # ── Africa ───────────────────────────────────────────────────────────────
    _c("johannesburg", "Johannesburg", "ஜோஹான்ஸ்பர்க்", -26.2041, 28.0473, "ZA", "Africa/Johannesburg", 2.0),
    _c("cape_town", "Cape Town", "கேப் டவுன்", -33.9249, 18.4241, "ZA", "Africa/Johannesburg", 2.0),
    _c("durban", "Durban", "டர்பன்", -29.8587, 31.0218, "ZA", "Africa/Johannesburg", 2.0),
    _c("nairobi", "Nairobi", "நைரோபி", -1.2921, 36.8219, "KE", "Africa/Nairobi", 3.0),
    _c("port_louis", "Port Louis", "போர்ட் லூயிஸ்", -20.1609, 57.5012, "MU", "Indian/Mauritius", 4.0),
    _c("cairo", "Cairo", "கெய்ரோ", 30.0444, 31.2357, "EG", "Africa/Cairo", 2.0),
    _c("lagos", "Lagos", "லாகோஸ்", 6.5244, 3.3792, "NG", "Africa/Lagos", 1.0),

    # ── East Asia ────────────────────────────────────────────────────────────
    _c("tokyo", "Tokyo", "டோக்கியோ", 35.6762, 139.6503, "JP", "Asia/Tokyo", 9.0),
    _c("osaka", "Osaka", "ஒசாகா", 34.6937, 135.5023, "JP", "Asia/Tokyo", 9.0),
    _c("seoul", "Seoul", "சியோல்", 37.5665, 126.9780, "KR", "Asia/Seoul", 9.0),
    _c("hong_kong", "Hong Kong", "ஹாங்காங்", 22.3193, 114.1694, "HK", "Asia/Hong_Kong", 8.0),
    _c("taipei", "Taipei", "தாய்பே", 25.0330, 121.5654, "TW", "Asia/Taipei", 8.0),
    _c("beijing", "Beijing", "பெய்ஜிங்", 39.9042, 116.4074, "CN", "Asia/Shanghai", 8.0),
    _c("shanghai", "Shanghai", "ஷாங்காய்", 31.2304, 121.4737, "CN", "Asia/Shanghai", 8.0),

    # ── South America ────────────────────────────────────────────────────────
    _c("sao_paulo", "São Paulo", "சாவோ பாவுலோ", -23.5505, -46.6333, "BR", "America/Sao_Paulo", -3.0),
    _c("rio_de_janeiro", "Rio de Janeiro", "ரியோ டி ஜெனிரோ", -22.9068, -43.1729, "BR", "America/Sao_Paulo", -3.0),
    _c("buenos_aires", "Buenos Aires", "புவெனஸ் ஐரிஸ்", -34.6037, -58.3816, "AR", "America/Argentina/Buenos_Aires", -3.0),
    _c("lima", "Lima", "லிமா", -12.0464, -77.0428, "PE", "America/Lima", -5.0),
    _c("bogota", "Bogotá", "போகோட்டா", 4.7110, -74.0721, "CO", "America/Bogota", -5.0),
    _c("santiago", "Santiago", "சாண்டியாகோ", -33.4489, -70.6693, "CL", "America/Santiago", -4.0),

    # ── Caribbean & Pacific ──────────────────────────────────────────────────
    _c("port_of_spain", "Port of Spain", "போர்ட் ஆஃப் ஸ்பெயின்", 10.6596, -61.5089, "TT", "America/Port_of_Spain", -4.0),
    _c("suva", "Suva", "சுவா", -18.1248, 178.4501, "FJ", "Pacific/Fiji", 12.0),
    _c("honolulu", "Honolulu", "ஹோனோலூலு", 21.3069, -157.8583, "US", "Pacific/Honolulu", -10.0),
]
# fmt: on


def city_by_id(city_id: str) -> CitySeed | None:
    for city in WORLD_CITIES:
        if city.id == city_id:
            return city
    return None


def format_display_name(name_en: str, name_ta: str) -> str:
    """Bilingual label for pickers — e.g. Chennai - சென்னை (works with Tamil keyboard)."""
    en = name_en.strip()
    ta = name_ta.strip()
    if ta and ta != en:
        return f"{en} - {ta}"
    return en
