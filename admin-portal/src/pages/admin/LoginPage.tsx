import React, { useState } from 'react';
import { ShieldCheck, Lock, Mail, ArrowRight, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Modal } from '../../components/common/Modal';
import { authService } from '../../services/authService';

export const LoginPage: React.FC<{ onSuccess?: () => void }> = ({ onSuccess }) => {
  const { signIn, isLoading, error: authContextError, clearError } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);

  // Forgot password modal
  const [forgotModalOpen, setForgotModalOpen] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotLoading, setForgotLoading] = useState(false);
  const [forgotMessage, setForgotMessage] = useState<{ success: boolean; text: string } | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    clearError();

    if (!email.trim() || !password.trim()) {
      setLocalError('Please provide both email and password.');
      return;
    }

    const res = await signIn(email.trim(), password);
    if (res.success) {
      if (onSuccess) onSuccess();
    } else {
      setLocalError(res.error || 'Authentication failed. Please verify credentials.');
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!forgotEmail.trim()) return;

    setForgotLoading(true);
    setForgotMessage(null);

    const res = await authService.resetPassword(forgotEmail.trim());
    setForgotLoading(false);
    setForgotMessage({
      success: res.success,
      text: res.message,
    });
  };

  const activeError = localError || authContextError;

  return (
    <div className="min-h-screen bg-zinc-50 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 relative selection:bg-zinc-900 selection:text-white">
      {/* Background Subtle Light Grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#e4e4e780_1px,transparent_1px),linear-gradient(to_bottom,#e4e4e780_1px,transparent_1px)] bg-[size:3.5rem_3.5rem] pointer-events-none" />

      <div className="sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        {/* Brand Header */}
        <div className="text-center">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-zinc-900 text-white font-black text-xl shadow-md mb-3.5">
            W
          </div>
          <div className="text-xs font-bold tracking-widest text-zinc-500 uppercase">
            WRINDHAOS
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-zinc-900 sm:text-3xl">
            Admin Portal
          </h1>
          <p className="mt-2 text-xs text-zinc-500 max-w-xs mx-auto leading-relaxed">
            Restricted access. Authorized administrator credentials and verified privileges are required.
          </p>
        </div>

        {/* Login Box */}
        <div className="mt-7 bg-white border border-zinc-200/90 py-8 px-6 shadow-sm rounded-2xl sm:px-10">
          <form className="space-y-5" onSubmit={handleSubmit}>
            {activeError && (
              <div className="p-3.5 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-start gap-2.5">
                <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                <span className="leading-relaxed font-medium">{activeError}</span>
              </div>
            )}

            <div>
              <Input
                label="Administrator Email"
                type="email"
                required
                autoComplete="email"
                placeholder="admin@wrindhaos.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                leftIcon={<Mail className="w-4 h-4" />}
              />
            </div>

            <div>
              <Input
                label="Password"
                type="password"
                required
                autoComplete="current-password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                leftIcon={<Lock className="w-4 h-4" />}
              />
            </div>

            <div className="flex items-center justify-between">
              <div className="text-xs text-zinc-500 flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-zinc-600" />
                <span className="font-medium">SUPER_ADMIN Protected</span>
              </div>
              <button
                type="button"
                onClick={() => {
                  setForgotEmail(email);
                  setForgotMessage(null);
                  setForgotModalOpen(true);
                }}
                className="text-xs font-medium text-zinc-600 hover:text-zinc-900 underline transition-colors cursor-pointer"
              >
                Forgot password?
              </button>
            </div>

            <div>
              <Button
                type="submit"
                variant="primary"
                size="lg"
                isLoading={isLoading}
                rightIcon={<ArrowRight className="w-4 h-4" />}
                className="w-full bg-zinc-900 text-white hover:bg-zinc-800 font-semibold"
              >
                Sign In
              </Button>
            </div>
          </form>
        </div>

        {/* Security Notice */}
        <p className="mt-6 text-center text-[11px] text-zinc-400">
          All administrative sessions and user management actions are audited in accordance with WrindhaOS privacy policies.
        </p>
      </div>

      {/* Forgot Password Modal */}
      <Modal
        isOpen={forgotModalOpen}
        onClose={() => setForgotModalOpen(false)}
        title="Reset Administrator Password"
        subtitle="Provide your administrator email to receive password recovery instructions."
      >
        <form onSubmit={handleForgotPassword} className="space-y-4">
          <Input
            label="Email Address"
            type="email"
            required
            placeholder="admin@wrindhaos.com"
            value={forgotEmail}
            onChange={(e) => setForgotEmail(e.target.value)}
            leftIcon={<Mail className="w-4 h-4" />}
          />

          {forgotMessage && (
            <div
              className={`p-3 rounded-lg text-xs flex items-start gap-2 border ${
                forgotMessage.success
                  ? 'bg-emerald-50 text-emerald-900 border-emerald-200'
                  : 'bg-rose-50 text-rose-900 border-rose-200'
              }`}
            >
              {forgotMessage.success ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
              ) : (
                <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
              )}
              <span>{forgotMessage.text}</span>
            </div>
          )}

          <div className="flex items-center justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setForgotModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              size="sm"
              isLoading={forgotLoading}
            >
              Send Instructions
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
