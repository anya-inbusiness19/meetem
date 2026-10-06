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
- **Nearest first**: matches start with students at your school, then the closest campuses and cities; filter by any city or state
- **Profile pages**: every student has a page with a custom banner, an About me description and sections for basics, free time, interests, talents and more
- **Fun tab**: a weekly Talent Show (60-second videos, one vote per student), an avatar maker, and 8 games with leaderboards: Campus Dash (runner), Sky Obby (obstacle course), Lights Out (horror maze), Lava Rise (tower climb), Color Block (party), Disaster Dodge (survival), Side Hustle Tycoon (make money) and Pet Hatch (pet simulator)
- **Fair match %**: the match % only counts what two students share, so both people see the same number
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
- `profile-page-setup.sql`: Supabase setup for descriptions, banners and viewing profiles (run once)
- `games-setup.sql`: Supabase setup for game leaderboards and saved progress (run once)
- `fun-setup.sql`: Supabase setup for avatars, the leaderboard and the Talent Show (run once in the SQL Editor)

## Author

Built by A’Nya Hill, Business Administration student at Calhoun Community College.
