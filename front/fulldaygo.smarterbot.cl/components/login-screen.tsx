"use client"

import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { useLanguage } from "@/contexts/language-context"
import { LanguageToggle } from "@/components/language-toggle"
import Image from "next/image"

interface LoginScreenProps {
  onLogin: (user: any) => void
}

export function LoginScreen({ onLogin }: LoginScreenProps) {
  const { t } = useLanguage()

  const handleGoogleLogin = () => {
    // Simular login con Google
    const mockUser = {
      name: "María González",
      email: "maria@gmail.com",
      avatar: "/woman-profile.png",
    }
    onLogin(mockUser)
  }

  return (
    <div
      className="h-full relative"
      style={{
        backgroundImage: "url(/ski-background.png)",
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }}
    >
      <div className="absolute inset-0 bg-black/20 backdrop-blur-[1px]"></div>

      {/* Language toggle en la esquina superior derecha */}
      <div className="absolute top-8 right-4 z-20">
        <LanguageToggle />
      </div>

      <div className="relative z-10 h-full flex items-center justify-center p-6 pt-12">
        <div className="w-full max-w-sm space-y-6">
          {/* Logo y título */}
          <div className="text-center space-y-4">
            <div className="flex justify-center items-center mb-4">
              <div className="p-3 rounded-2xl bg-white/10 backdrop-blur-xl border border-white/20">
                <Image
                  src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/fullday-logo-ksSzhT3mt7XJU40mJl9eWhqlBklcN1.png"
                  alt="FulldayGO Logo"
                  width={80}
                  height={80}
                  className="w-20 h-20 object-contain"
                />
              </div>
            </div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-500 to-blue-600 bg-clip-text text-transparent">
              {t("login.title")}
            </h1>
            <p className="text-gray-600 text-sm px-2">{t("login.subtitle")}</p>
          </div>

          {/* Card de login con efecto liquid glass */}
          <Card className="p-5 bg-white/20 backdrop-blur-xl border border-white/30 shadow-2xl">
            <div className="space-y-5">
              <div className="text-center">
                <h2 className="text-lg font-semibold text-gray-800 mb-2">{t("login.welcome")}</h2>
                <p className="text-gray-600 text-sm">{t("login.description")}</p>
              </div>

              <Button
                onClick={handleGoogleLogin}
                className="w-full h-11 bg-white/30 hover:bg-white/40 backdrop-blur-xl border border-white/40 text-gray-800 font-medium rounded-xl transition-all duration-300"
              >
                <svg className="w-4 h-4 mr-2" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  />
                </svg>
                {t("login.continueGoogle")}
              </Button>

              <div className="text-center text-xs text-gray-500">{t("login.terms")}</div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}
