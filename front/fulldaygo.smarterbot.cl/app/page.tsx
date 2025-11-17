"use client"

import { useState } from "react"
import { LoginScreen } from "@/components/login-screen"
import { HomeScreen } from "@/components/home-screen"
import { CouponDetail } from "@/components/coupon-detail"
import { ProfileScreen } from "@/components/profile-screen"
import { LanguageProvider } from "@/contexts/language-context"

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<"login" | "home" | "coupon" | "profile">("login")
  const [selectedCoupon, setSelectedCoupon] = useState<any>(null)
  const [user, setUser] = useState<any>(null)

  const handleLogin = (userData: any) => {
    setUser(userData)
    setCurrentScreen("home")
  }

  const handleCouponSelect = (coupon: any) => {
    setSelectedCoupon(coupon)
    setCurrentScreen("coupon")
  }

  const handleBack = () => {
    if (currentScreen === "coupon") {
      setCurrentScreen("home")
    } else if (currentScreen === "profile") {
      setCurrentScreen("home")
    }
  }

  const handleProfileOpen = () => {
    setCurrentScreen("profile")
  }

  return (
    <LanguageProvider>
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
        {/* Contenedor del dispositivo móvil */}
        <div className="relative">
          {/* Marco del teléfono */}
          <div className="w-[375px] h-[812px] bg-black rounded-[3rem] p-2 shadow-2xl">
            {/* Pantalla del teléfono */}
            <div className="w-full h-full bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 rounded-[2.5rem] overflow-hidden relative">
              {/* Notch del iPhone */}
              <div className="absolute top-0 left-1/2 transform -translate-x-1/2 w-32 h-6 bg-black rounded-b-2xl z-50"></div>

              {/* Contenido de la app */}
              <div className="w-full h-full overflow-y-auto">
                {currentScreen === "login" && <LoginScreen onLogin={handleLogin} />}
                {currentScreen === "home" && (
                  <HomeScreen user={user} onCouponSelect={handleCouponSelect} onProfileOpen={handleProfileOpen} />
                )}
                {currentScreen === "coupon" && selectedCoupon && (
                  <CouponDetail coupon={selectedCoupon} onBack={handleBack} />
                )}
                {currentScreen === "profile" && <ProfileScreen user={user} onBack={handleBack} />}
              </div>
            </div>
          </div>

          {/* Botón home del iPhone */}
          <div className="absolute bottom-1 left-1/2 transform -translate-x-1/2 w-32 h-1 bg-white rounded-full opacity-60"></div>
        </div>
      </div>
    </LanguageProvider>
  )
}
