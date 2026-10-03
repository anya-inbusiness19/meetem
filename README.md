# MeetEm'

**Meet college students who are free when you are.**

Live: [meetem.org](https://meetem.org) · Demo (no account needed): [meetem.org/demo.html](https://meetem.org/demo.html)

MeetEm' is a web app (PWA) that matches college students by free time, interests and goals, then helps them meet up in small groups in person. It's built for students who want real-life friends and study partners, not another feed.

## Features

- **Verified students only**: sign-up requires a school .edu email and a confirmation code
- **Smart matches**: compares free times, interests, goals and talents, and explains each match
- **Wave to connect**: a private chat opens only when both people wave
- **Events & deals**: students post study groups, game nights and deals; joining opens a group chat
- **Profiles**: photos, an optional video, music links, fun facts
- **Safety**: email, phone and ZIP are never shown to matches; report and block tools; meet-in-public reminders

## Tech

| Part | Tool |
| --- | --- |
| Front end | HTML, CSS, JavaScript (single-page app, installable as a PWA) |
| Accounts, database, file storage | Supabase (Postgres, Auth, Storage) |
| Hosting | Cloudflare Pages, deployed from this repo |
| Confirmation emails | Brevo SMTP on the meetem.org domain |
| Development | AI-assisted with Claude |

## Files

- `index.html`: landing page, sign-up and the full app
- `demo.html`: clickable demo with sample students (no account, nothing saved)
- `privacy.html`: privacy policy

## Author

Built by A’Nya Hill, Business Administration student at Calhoun Community College.
