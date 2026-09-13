# Asistan

I built this for myself.

I needed one Mac app where I could keep client work, invoices, and project tasks on one side, and university stuff on the other — without mixing them. Work mode is jobs, payments, and how far a project actually is. Student mode is courses, grades, homework, and scholarship applications. I study Computer Engineering at Kırıkkale University, so the GPA math follows KKÜ’s letter scale (AA 88–100 down to FF).

It’s a native macOS app. You unlock it with Touch ID. Everything lives in your own Supabase project, not in this repo.

If you want to use it, fork it and point it at **your** database. My keys and my rows are not in here. They never should be.

## What it does

Work mode: add a job, and a project is created with it. You can plan payments (date, amount) and mark them paid when the money lands. Tasks on the project fill up the completion percentage as you check them off. There’s a simple finance view, a calendar, goals, and notes.

Student mode: enter courses and exam scores, see term / overall GPA and a small progress chart, and get the minimum final you need to pass (CC, or DC/DD if your GPA is at least 2.00). You can keep a weekly schedule, homework, notes about courses and lecturers, and scholarship applications (applied / in review / accepted / rejected). There’s a button that opens the [KKÜ student portal](https://obs.kku.edu.tr/).

Both sides can ping you about due dates. After the first setup, opening the app is just Touch ID.

## What is not in this repo

No Project URL, no anon key, no password, no jobs, no grades. Those stay on your Mac (Keychain) and in your Supabase tables.

Don’t commit `build/`, `.env`, or anything that looks like a secret. `.gitignore` already covers the usual junk.

## You need

- macOS 14+
- Xcode 16+ (only to compile it once)
- A free [Supabase](https://supabase.com) project
- Touch ID if you have it; otherwise the Mac password works

## Setup

### 1. Your Supabase project

Create a new project. In the SQL Editor, paste all of `supabase/schema.sql` and run it.

Under Authentication, keep Email enabled. If it’s just you, turn **Confirm email** off so the first sign-up actually lets you in.

In Project Settings → API, copy:

- **Project URL** — only `https://xxxx.supabase.co` (no trailing slash, not the dashboard link)
- the **anon / publishable** key

Leave `service_role` alone. Don’t put it in the app.

### 2. Put it on your Desktop

```bash
git clone https://github.com/saydamdaghan/macOS-assistant-app.git
cd macOS-assistant-app
chmod +x Scripts/install-local.sh
./Scripts/install-local.sh
```

That builds a release and drops `Asistan.app` on your Desktop. Double-click it. If macOS complains, right-click → Open.

To put it in Applications instead:

```bash
./Scripts/install-local.sh /Applications/Asistan.app
```

When you change the code, run the script again. Your login stays in Keychain.

### 3. First launch

The first screen asks for your Project URL, anon key, name, email, and password. Use **New account**, then **Continue**. After that it’s Touch ID, then pick Work or Student.

On another Mac, use the same Supabase project and the same email/password. You’ll type the URL and key once on that machine too.

### Optional: run from Xcode

Open `Asistan.xcodeproj`, make sure the scheme is **Asistan**, hit Run. Signing can stay “Sign to Run Locally”. The widget target is not embedded, on purpose — it was blocking local runs without a paid Apple team.

## If something breaks

**Invalid path specified in request URL** — the Project URL is wrong. It has to be exactly `https://xxxx.supabase.co`.

**Signing / development certificate** — scheme should be Asistan, not AsistanWidgets. Clean Build Folder and try again.

**Account created but I can’t get in** — turn off email confirmation in Supabase, then sign in with **Existing account**.

That’s it. I made this to keep my own work and school life in one place. If it helps you too, take it and wire it to your own project.
