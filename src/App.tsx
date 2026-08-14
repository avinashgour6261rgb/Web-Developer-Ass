import { useState } from 'react';
import { Truck, Sparkles, Clock, ArrowRight, CheckCircle2, Phone, Mail, User, Loader2 } from 'lucide-react';

const HERO_IMG = 'https://images.pexels.com/photos/8774511/pexels-photo-8774511.jpeg?auto=compress&cs=tinysrgb&h=900&w=1400';

const features = [
  {
    icon: <Truck className="h-7 w-7" />,
    title: 'Free Pickup & Delivery',
    text: 'We collect from your door and return everything freshly folded — no trips to the laundromat, ever.',
  },
  {
    icon: <Sparkles className="h-7 w-7" />,
    title: 'Pro Wash & Fold',
    text: 'Premium detergents, careful sorting, and expert folding. Your clothes come back clean, soft, and neat.',
  },
  {
    icon: <Clock className="h-7 w-7" />,
    title: '24-Hour Turnaround',
    text: 'Schedule a pickup today and get your laundry back the next day. Same-day available on request.',
  },
];

interface FormData {
  name: string;
  email: string;
  phone: string;
}
interface Errors {
  name?: string;
  email?: string;
  phone?: string;
}

export default function App() {
  const [form, setForm] = useState<FormData>({ name: '', email: '', phone: '' });
  const [errors, setErrors] = useState<Errors>({});
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  const validate = (data: FormData): Errors => {
    const errs: Errors = {};
    if (!data.name.trim()) {
      errs.name = 'Please enter your name';
    } else if (data.name.trim().length < 2) {
      errs.name = 'Name must be at least 2 characters';
    }
    if (!data.email.trim()) {
      errs.email = 'Please enter your email';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email.trim())) {
      errs.email = 'Please enter a valid email address';
    }
    if (!data.phone.trim()) {
      errs.phone = 'Please enter your phone number';
    } else {
      const digits = data.phone.replace(/[\s\-().]/g, '');
      if (!/^\+?\d{7,15}$/.test(digits)) {
        errs.phone = 'Please enter a valid phone number (7–15 digits)';
      }
    }
    return errs;
  };

  const handleChange = (field: keyof FormData) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((f) => ({ ...f, [field]: e.target.value }));
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: undefined }));
    if (success) setSuccess(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs = validate(form);
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;

    setSubmitting(true);
    await new Promise((r) => setTimeout(r, 900));
    setSubmitting(false);
    setSuccess(true);
    setForm({ name: '', email: '', phone: '' });
  };

  return (
    <div className="min-h-screen bg-cream-50">
      {/* HERO */}
      <section className="relative overflow-hidden">
        {/* Background */}
        <div className="absolute inset-0">
          <img
            src={HERO_IMG}
            alt="Neatly folded fresh towels"
            className="h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-br from-ink-950/85 via-ink-900/70 to-brand-900/60" />
        </div>

        {/* Decorative circles */}
        <div className="pointer-events-none absolute -right-24 top-10 h-72 w-72 rounded-full border border-white/10 animate-spin-slow" />
        <div className="pointer-events-none absolute -left-16 bottom-0 h-48 w-48 rounded-full border border-brand-300/20 animate-float" />

        <div className="container-px relative z-10 flex min-h-screen flex-col">
          {/* Nav */}
          <nav className="flex items-center justify-between py-6">
            <div className="flex items-center gap-2.5">
              <div className="grid h-10 w-10 place-items-center rounded-xl bg-brand-500 text-white shadow-lg shadow-brand-500/30">
                <RefreshIcon />
              </div>
              <span className="font-serif text-xl font-semibold text-white">
                Loop <span className="text-brand-300">&amp;</span> Fold
              </span>
            </div>
            <a href="#book" className="hidden rounded-full border border-white/20 px-5 py-2 text-sm font-medium text-white transition hover:bg-white/10 sm:block">
              Book a Pickup
            </a>
          </nav>

          {/* Content */}
          <div className="flex flex-1 flex-col justify-center py-16">
            <div className="max-w-2xl">
              <div className="animate-fade-up inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-4 py-1.5 text-xs font-medium uppercase tracking-ultra text-brand-200 backdrop-blur">
                <Sparkles className="h-3.5 w-3.5" />
                Pickup &amp; delivery laundry service
              </div>

              <h1
                className="mt-6 font-serif text-5xl font-semibold leading-[1.05] tracking-tightest text-white sm:text-6xl lg:text-7xl animate-fade-up"
                style={{ animationDelay: '0.1s' }}
              >
                Laundry day,
                <br />
                <span className="text-brand-300">handled.</span>
              </h1>

              <p
                className="mt-6 max-w-lg text-lg leading-relaxed text-cream-100/80 animate-fade-up"
                style={{ animationDelay: '0.2s' }}
              >
                We pick up your laundry, wash and fold it with care, and deliver it back to your door in 24 hours. Sit back — we&rsquo;ve got the folding covered.
              </p>

              <div
                className="mt-9 flex flex-col gap-4 sm:flex-row sm:items-center animate-fade-up"
                style={{ animationDelay: '0.3s' }}
              >
                <a href="#book" className="btn-brand text-base">
                  Book Your First Pickup
                  <ArrowRight className="h-4 w-4" />
                </a>
                <div className="flex items-center gap-3 text-sm text-cream-100/70">
                  <CheckCircle2 className="h-5 w-5 text-brand-300" />
                  First pickup is free
                </div>
              </div>
            </div>
          </div>

          {/* Stats strip */}
          <div
            className="grid grid-cols-3 gap-4 border-t border-white/10 py-6 text-center animate-fade-up"
            style={{ animationDelay: '0.4s' }}
          >
            <Stat value="24h" label="Turnaround" />
            <Stat value="12k+" label="Loads folded" />
            <Stat value="4.9★" label="Customer rating" />
          </div>
        </div>
      </section>

      {/* FEATURES */}
      <section className="container-px py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-ultra text-brand-600">Why Loop &amp; Fold</p>
          <h2 className="mt-3 font-serif text-3xl font-semibold tracking-tight text-ink-950 sm:text-4xl lg:text-5xl">
            Three reasons to never fold again
          </h2>
          <p className="mt-4 text-ink-500">
            We built Loop &amp; Fold around the things that matter: convenience, quality, and speed.
          </p>
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {features.map((f, i) => (
            <div
              key={f.title}
              className="group rounded-3xl border border-ink-950/8 bg-white p-8 shadow-sm transition-all duration-500 hover:-translate-y-1.5 hover:border-brand-300 hover:shadow-xl hover:shadow-brand-600/10"
              style={{ animationDelay: `${i * 0.1}s` }}
            >
              <div className="grid h-14 w-14 place-items-center rounded-2xl bg-brand-50 text-brand-600 transition-colors duration-500 group-hover:bg-brand-600 group-hover:text-white">
                {f.icon}
              </div>
              <h3 className="mt-6 font-serif text-2xl font-semibold text-ink-950">{f.title}</h3>
              <p className="mt-3 leading-relaxed text-ink-500">{f.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* BOOKING FORM */}
      <section id="book" className="bg-brand-700 py-20 lg:py-28">
        <div className="container-px">
          <div className="mx-auto max-w-2xl rounded-3xl bg-white p-8 shadow-2xl shadow-brand-950/20 sm:p-12">
            <div className="text-center">
              <p className="text-xs font-semibold uppercase tracking-ultra text-brand-600">Book a Pickup</p>
              <h2 className="mt-3 font-serif text-3xl font-semibold tracking-tight text-ink-950 sm:text-4xl">
                Schedule your first pickup
              </h2>
              <p className="mt-3 text-ink-500">
                Fill in your details and we&rsquo;ll text you a pickup window. First pickup is on us.
              </p>
            </div>

            {success ? (
              <div className="mt-8 flex flex-col items-center rounded-2xl border border-brand-200 bg-brand-50 p-10 text-center animate-fade-up">
                <div className="grid h-16 w-16 place-items-center rounded-full bg-brand-500 text-white">
                  <CheckCircle2 className="h-8 w-8" />
                </div>
                <h3 className="mt-5 font-serif text-2xl font-semibold text-ink-950">You&rsquo;re all set!</h3>
                <p className="mt-2 max-w-sm text-ink-500">
                  We&rsquo;ve received your booking request. Our team will reach out within 2 hours to confirm your pickup window.
                </p>
                <button
                  onClick={() => setSuccess(false)}
                  className="mt-6 rounded-full border border-ink-950/15 px-5 py-2.5 text-sm font-medium text-ink-700 transition hover:bg-cream-100"
                >
                  Book another pickup
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} noValidate className="mt-8 space-y-5">
                {/* Name */}
                <Field
                  label="Full Name"
                  icon={<User className="h-4 w-4" />}
                  error={errors.name}
                >
                  <input
                    type="text"
                    name="name"
                    autoComplete="name"
                    placeholder="Jordan Ellis"
                    value={form.name}
                    onChange={handleChange('name')}
                    className={`w-full bg-transparent text-sm text-ink-950 placeholder-ink-300 outline-none ${
                      errors.name ? '' : ''
                    }`}
                  />
                </Field>

                {/* Email */}
                <Field
                  label="Email Address"
                  icon={<Mail className="h-4 w-4" />}
                  error={errors.email}
                >
                  <input
                    type="email"
                    name="email"
                    autoComplete="email"
                    placeholder="jordan@example.com"
                    value={form.email}
                    onChange={handleChange('email')}
                    className="w-full bg-transparent text-sm text-ink-950 placeholder-ink-300 outline-none"
                  />
                </Field>

                {/* Phone */}
                <Field
                  label="Phone Number"
                  icon={<Phone className="h-4 w-4" />}
                  error={errors.phone}
                >
                  <input
                    type="tel"
                    name="phone"
                    autoComplete="tel"
                    placeholder="(555) 123-4567"
                    value={form.phone}
                    onChange={handleChange('phone')}
                    className="w-full bg-transparent text-sm text-ink-950 placeholder-ink-300 outline-none"
                  />
                </Field>

                <button
                  type="submit"
                  disabled={submitting}
                  className="btn-brand w-full text-base"
                >
                  {submitting ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Booking your pickup...
                    </>
                  ) : (
                    <>
                      Book My Free Pickup
                      <ArrowRight className="h-4 w-4" />
                    </>
                  )}
                </button>

                <p className="text-center text-xs text-ink-400">
                  No card required. We&rsquo;ll confirm by text within 2 hours.
                </p>
              </form>
            )}
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="bg-ink-950 py-10 text-center text-sm text-ink-300">
        <div className="container-px">
          <div className="flex items-center justify-center gap-2.5">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-brand-500 text-white">
              <RefreshIcon size={16} />
            </div>
            <span className="font-serif text-lg font-semibold text-white">
              Loop <span className="text-brand-300">&amp;</span> Fold
            </span>
          </div>
          <p className="mt-4 text-ink-400">
            Pickup &amp; delivery laundry and dry cleaning. Fresh folds, zero effort.
          </p>
          <p className="mt-4 text-xs text-ink-500">
            &copy; {new Date().getFullYear()} Loop &amp; Fold. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div>
      <p className="font-serif text-2xl font-semibold text-white sm:text-3xl">{value}</p>
      <p className="mt-0.5 text-xs uppercase tracking-wider text-cream-100/60">{label}</p>
    </div>
  );
}

function Field({
  label,
  icon,
  error,
  children,
}: {
  label: string;
  icon: React.ReactNode;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-ink-400">
        {label}
      </label>
      <div
        className={`flex items-center gap-3 rounded-xl border bg-cream-50 px-4 py-3.5 transition-colors duration-200 ${
          error
            ? 'border-red-400 bg-red-50/40 focus-within:border-red-500'
            : 'border-ink-950/10 focus-within:border-brand-500'
        }`}
      >
        <span className={error ? 'text-red-400' : 'text-ink-300'}>{icon}</span>
        {children}
      </div>
      {error && (
        <p className="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-red-500">
          <span className="inline-block h-1 w-1 rounded-full bg-red-500" />
          {error}
        </p>
      )}
    </div>
  );
}

function RefreshIcon({ size = 20 }: { size?: number }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M3 12a9 9 0 0 1 15-6.7L21 8" />
      <path d="M21 3v5h-5" />
      <path d="M21 12a9 9 0 0 1-15 6.7L3 16" />
      <path d="M3 21v-5h5" />
    </svg>
  );
}
