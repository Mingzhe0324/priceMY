from pathlib import Path
p=Path(__file__).resolve().parents[1]/'apps/mobile/android/app/src/main/AndroidManifest.xml'
if p.exists():
    s=p.read_text()
    if 'android.permission.INTERNET' not in s:
        s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
    p.write_text(s)
