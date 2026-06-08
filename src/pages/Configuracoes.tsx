import { useState, useRef } from 'react';
import type { FormEvent } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Camera, 
  Trash2, 
  Key, 
  User, 
  Mail, 
  AlertCircle, 
  Sparkles, 
  Eye, 
  EyeOff,
  UserCheck
} from 'lucide-react';

export default function Configuracoes() {
  const { profile, user, refreshProfile } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Estados do Perfil
  const [nome, setNome] = useState(profile?.nome || '');
  const [loadingProfile, setLoadingProfile] = useState(false);
  const [profileError, setProfileError] = useState<string | null>(null);
  const [profileSuccess, setProfileSuccess] = useState<string | null>(null);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);

  // Estados da Senha
  const [novaSenha, setNovaSenha] = useState('');
  const [confirmarSenha, setConfirmarSenha] = useState('');
  const [showSenha, setShowSenha] = useState(false);
  const [showConfirmSenha, setShowConfirmSenha] = useState(false);
  const [loadingPassword, setLoadingPassword] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordSuccess, setPasswordSuccess] = useState<string | null>(null);

  const userName = profile?.nome || 'Usuário';
  const userEmail = profile?.email || user?.email || '';
  const initials = userName
    .split(' ')
    .map((n) => n[0] || '')
    .join('')
    .substring(0, 2)
    .toUpperCase();

  // 1. Atualizar informações de perfil (Nome)
  const handleUpdateProfile = async (e: FormEvent) => {
    e.preventDefault();
    setProfileError(null);
    setProfileSuccess(null);

    if (!nome.trim()) {
      setProfileError('O nome completo não pode ficar em branco.');
      return;
    }

    setLoadingProfile(true);
    try {
      const { error } = await supabase
        .from('usuarios')
        .update({ nome: nome.trim() })
        .eq('id', user?.id);

      if (error) throw error;

      setProfileSuccess('Perfil atualizado com sucesso!');
      await refreshProfile();
    } catch (err: any) {
      console.error(err);
      setProfileError(err.message || 'Falha ao atualizar o perfil.');
    } finally {
      setLoadingProfile(false);
    }
  };

  // 2. Fazer Upload do Avatar para Supabase Storage
  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user?.id) return;

    setProfileError(null);
    setProfileSuccess(null);
    setUploadingAvatar(true);

    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}-${Date.now()}.${fileExt}`;
      const filePath = `public/avatars/${fileName}`;

      // Upload do arquivo para o bucket publico 'avatars'
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { cacheControl: '3600', upsert: true });

      if (uploadError) throw uploadError;

      // Obter URL pública do arquivo
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

      // Salvar URL pública na tabela 'usuarios'
      const { error: updateError } = await supabase
        .from('usuarios')
        .update({ avatar_url: publicUrl })
        .eq('id', user.id);

      if (updateError) throw updateError;

      setProfileSuccess('Foto de perfil atualizada!');
      await refreshProfile();
    } catch (err: any) {
      console.error(err);
      setProfileError(err.message || 'Erro ao enviar foto de perfil.');
    } finally {
      setUploadingAvatar(false);
      if (fileInputRef.current) fileInputRef.current.value = ''; // Limpar input
    }
  };

  // 3. Remover foto de perfil (limpar avatar_url no banco)
  const handleRemoveAvatar = async () => {
    if (!user?.id) return;
    setProfileError(null);
    setProfileSuccess(null);
    setUploadingAvatar(true);

    try {
      const { error } = await supabase
        .from('usuarios')
        .update({ avatar_url: null })
        .eq('id', user.id);

      if (error) throw error;

      setProfileSuccess('Foto de perfil removida.');
      await refreshProfile();
    } catch (err: any) {
      console.error(err);
      setProfileError(err.message || 'Erro ao remover foto de perfil.');
    } finally {
      setUploadingAvatar(false);
    }
  };

  // 4. Atualizar Senha (inline)
  const handleUpdatePassword = async (e: FormEvent) => {
    e.preventDefault();
    setPasswordError(null);
    setPasswordSuccess(null);

    if (novaSenha.length < 6) {
      setPasswordError('A nova senha deve conter no mínimo 6 caracteres.');
      return;
    }

    if (novaSenha !== confirmarSenha) {
      setPasswordError('As senhas não coincidem. Verifique a confirmação.');
      return;
    }

    setLoadingPassword(true);
    try {
      const { error } = await supabase.auth.updateUser({
        password: novaSenha
      });

      if (error) throw error;

      setPasswordSuccess('Senha alterada com sucesso!');
      setNovaSenha('');
      setConfirmarSenha('');
    } catch (err: any) {
      console.error(err);
      setPasswordError(err.message || 'Falha ao atualizar a senha.');
    } finally {
      setLoadingPassword(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Top Banner */}
      <div className="bg-white border border-border rounded-[14px] p-5 shadow-sm">
        <h2 className="font-title font-semibold text-2xl text-text-primary">Configurações</h2>
        <p className="text-xs text-text-secondary mt-0.5">Gerencie os detalhes do seu perfil e configurações de segurança de acesso.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Left Side: Avatar Panel */}
        <div className="md:col-span-1 bg-white border border-border rounded-[14px] p-6 shadow-sm flex flex-col items-center justify-center text-center h-fit">
          <div className="relative group">
            {profile?.avatar_url ? (
              <img 
                src={profile.avatar_url} 
                alt={userName} 
                className="w-28 h-28 rounded-full object-cover border-2 border-rose-200 shadow-md"
              />
            ) : (
              <div className="w-28 h-28 rounded-full bg-rose-100 border-2 border-rose-200 text-rose-800 flex items-center justify-center font-title font-bold text-3xl shadow-sm">
                {initials}
              </div>
            )}
            
            {/* Hover Camera overlay */}
            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={uploadingAvatar}
              className="absolute inset-0 bg-black/40 rounded-full opacity-0 group-hover:opacity-100 flex items-center justify-center text-white transition-opacity cursor-pointer duration-200"
            >
              <Camera className="w-6 h-6" />
            </button>
          </div>

          <h3 className="font-title font-bold text-lg text-text-primary mt-4 truncate w-full">{userName}</h3>
          <p className="text-xs text-text-secondary truncate w-full">{userEmail}</p>

          <input 
            type="file" 
            ref={fileInputRef} 
            onChange={handleAvatarUpload} 
            accept="image/*" 
            className="hidden" 
          />

          <div className="flex flex-col gap-2 w-full mt-6">
            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={uploadingAvatar}
              className="flex items-center justify-center gap-1.5 px-3 py-2 bg-rose-50 hover:bg-rose-100 text-rose-800 text-xs font-semibold rounded-lg transition-colors cursor-pointer disabled:opacity-50"
            >
              <Camera className="w-4 h-4" />
              {uploadingAvatar ? 'Enviando...' : 'Alterar Foto'}
            </button>
            {profile?.avatar_url && (
              <button
                onClick={handleRemoveAvatar}
                disabled={uploadingAvatar}
                className="flex items-center justify-center gap-1.5 px-3 py-2 bg-red-50 hover:bg-red-100 text-red-800 text-xs font-semibold rounded-lg transition-colors cursor-pointer disabled:opacity-50"
              >
                <Trash2 className="w-4 h-4" />
                Remover Foto
              </button>
            )}
          </div>
        </div>

        {/* Right Side: Forms Panel */}
        <div className="md:col-span-2 space-y-6">
          
          {/* Section 1: Profile Details */}
          <div className="bg-white border border-border rounded-[14px] p-6 shadow-sm">
            <h3 className="font-title font-bold text-lg text-text-primary flex items-center gap-2 border-b border-border pb-3">
              <User className="w-5 h-5 text-rose-600" />
              Dados do Perfil
            </h3>
            
            <form onSubmit={handleUpdateProfile} className="mt-4 space-y-4">
              {profileError && (
                <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg flex items-center gap-2.5">
                  <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
                  <p className="text-xs font-medium">{profileError}</p>
                </div>
              )}

              {profileSuccess && (
                <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg flex items-center gap-2.5">
                  <Sparkles className="w-5 h-5 text-green-600 flex-shrink-0" />
                  <p className="text-xs font-medium">{profileSuccess}</p>
                </div>
              )}

              {/* Email field (Read-only) */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold uppercase tracking-wider text-text-secondary block">
                  E-mail de Acesso
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-text-muted">
                    <Mail className="w-4 h-4" />
                  </div>
                  <input
                    type="email"
                    disabled
                    value={userEmail}
                    className="w-full pl-10 pr-4 py-2 border border-border rounded-lg bg-bg text-text-muted text-sm cursor-not-allowed"
                  />
                </div>
                <p className="text-[10px] text-text-secondary">O e-mail de acesso não pode ser alterado diretamente.</p>
              </div>

              {/* Name field */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold uppercase tracking-wider text-text-secondary block">
                  Nome Completo <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-text-muted">
                    <UserCheck className="w-4 h-4" />
                  </div>
                  <input
                    type="text"
                    required
                    value={nome}
                    onChange={(e) => setNome(e.target.value)}
                    disabled={loadingProfile}
                    placeholder="Seu nome completo"
                    className="w-full pl-10 pr-4 py-2 border border-border rounded-lg bg-bg text-text-primary text-sm focus:outline-none focus:ring-1 focus:ring-rose-400 transition-all"
                  />
                </div>
              </div>

              <div className="flex justify-end pt-2">
                <button
                  type="submit"
                  disabled={loadingProfile}
                  className="px-4 py-2 bg-rose-600 hover:bg-rose-800 disabled:bg-rose-300 text-white rounded-lg text-xs font-semibold transition-colors cursor-pointer"
                >
                  {loadingProfile ? 'Salvando...' : 'Salvar Perfil'}
                </button>
              </div>
            </form>
          </div>

          {/* Section 2: Security (Password Change) */}
          <div className="bg-white border border-border rounded-[14px] p-6 shadow-sm">
            <h3 className="font-title font-bold text-lg text-text-primary flex items-center gap-2 border-b border-border pb-3">
              <Key className="w-5 h-5 text-rose-600" />
              Segurança e Acesso
            </h3>

            <form onSubmit={handleUpdatePassword} className="mt-4 space-y-4">
              {passwordError && (
                <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg flex items-center gap-2.5">
                  <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
                  <p className="text-xs font-medium">{passwordError}</p>
                </div>
              )}

              {passwordSuccess && (
                <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg flex items-center gap-2.5">
                  <Sparkles className="w-5 h-5 text-green-600 flex-shrink-0" />
                  <p className="text-xs font-medium">{passwordSuccess}</p>
                </div>
              )}

              {/* Password field */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold uppercase tracking-wider text-text-secondary block">
                  Nova Senha <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showSenha ? 'text' : 'password'}
                    required
                    placeholder="No mínimo 6 caracteres"
                    value={novaSenha}
                    onChange={(e) => setNovaSenha(e.target.value)}
                    disabled={loadingPassword}
                    className="w-full px-3 py-2 pr-10 border border-border rounded-lg bg-bg text-text-primary text-sm focus:outline-none focus:ring-1 focus:ring-rose-400 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowSenha(!showSenha)}
                    disabled={loadingPassword}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-text-muted hover:text-rose-600 cursor-pointer disabled:opacity-50"
                  >
                    {showSenha ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Confirm Password field */}
              <div className="space-y-1.5">
                <label className="text-xs font-semibold uppercase tracking-wider text-text-secondary block">
                  Confirmar Nova Senha <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showConfirmSenha ? 'text' : 'password'}
                    required
                    placeholder="Repita a nova senha"
                    value={confirmarSenha}
                    onChange={(e) => setConfirmarSenha(e.target.value)}
                    disabled={loadingPassword}
                    className="w-full px-3 py-2 pr-10 border border-border rounded-lg bg-bg text-text-primary text-sm focus:outline-none focus:ring-1 focus:ring-rose-400 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmSenha(!showConfirmSenha)}
                    disabled={loadingPassword}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-text-muted hover:text-rose-600 cursor-pointer disabled:opacity-50"
                  >
                    {showConfirmSenha ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div className="flex justify-end pt-2">
                <button
                  type="submit"
                  disabled={loadingPassword}
                  className="px-4 py-2 bg-rose-600 hover:bg-rose-800 disabled:bg-rose-300 text-white rounded-lg text-xs font-semibold transition-colors cursor-pointer"
                >
                  {loadingPassword ? 'Atualizando...' : 'Atualizar Senha'}
                </button>
              </div>
            </form>
          </div>

        </div>

      </div>
    </div>
  );
}
