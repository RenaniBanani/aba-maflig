# אבא מפליג – דף נחיתה

מה יש בתיקייה:
- `index.html` – הדף: הירו בגלילה, לו"ז, "מה זה אבא מפליג", שאלון והרשמה מוקדמת
- `frames/` – 185 פריימים לדסקטופ ו-185 למובייל (חיתוך לאורך)
- `config.js` – כאן מדביקים את פרטי Supabase (שני ערכים)
- `supabase.sql` – יוצר את טבלת התשובות עם כללי האבטחה
- `vercel.json` – cache ארוך לפריימים, כדי שביקור חוזר ייטען מיד
- `og-image.jpg` – התמונה שמופיעה כששולחים את הלינק בוואטסאפ

## 1. Supabase (5 דקות)
1. New project. אזור מומלץ: Frankfurt (eu-central-1), הכי קרוב לישראל.
2. SQL Editor → New query → מדביקים את כל `supabase.sql` → Run.
3. Project Settings → API (או API Keys): מעתיקים את ה-Project URL ואת המפתח הציבורי
   (anon / publishable). **לא** את ה-service_role / secret.
4. מדביקים את שניהם ב-`config.js`.

## 2. Vercel
אחת משתי דרכים:
- **GitHub:** מעלים את התיקייה ל-repo חדש → ב-Vercel: Add New → Project → Import. בלי build, Framework: Other.
- **טרמינל:** מתוך התיקייה: `npx vercel --prod`

## 3. דומיין משלך (לא חובה)
Vercel → Project → Settings → Domains → מוסיפים למשל `aba.banani.co.il`.
ב-Gandi LiveDNS מוסיפים רשומת CNAME: `aba` → `cname.vercel-dns.com`
(Vercel מציג את הערך המדויק אחרי שמוסיפים את הדומיין).

## 4. לראות את התשובות
- Supabase → Table Editor → `responses` – כל התשובות, אפשר לייצא ל-CSV.
- `early_list` – רק מי שהשאיר שם וטלפון.
- `summary` – כמה ענו, ממוצע הדירוג, כמה דירגו 4–5, כמה נרשמו.
מבקרים באתר יכולים רק לשלוח תשובה. הם לא יכולים לקרוא תשובות של אחרים.

## 5. לינקים למעקב לפי ערוץ
מוסיפים `?src=` ללינק, והערוץ נשמר עם כל תשובה בעמודה `source`:
- פודקאסט: `https://aba.banani.co.il/?src=podcast`
- אינסטגרם: `?src=instagram`
- וואטסאפ: `?src=whatsapp`
פרמטרים של `utm_` נשמרים גם הם, בעמודה `utm`.

## בדיקה לפני הפצה
פותחים את האתר, ממלאים את השאלון עד הסוף, ובודקים שהשורה הופיעה ב-`responses`.
אם מופיעה הודעה "הטופס עוד לא מחובר לשרת", חסרים הערכים ב-`config.js`.
