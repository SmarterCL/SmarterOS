"use client"

import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Settings, HelpCircle, LogOut, Gift, Star, Trophy, MapPin } from "lucide-react"
import { useLanguage } from "@/contexts/language-context"
import { LanguageToggle } from "@/components/language-toggle"

interface ProfileScreenProps {
  user: any
  onBack: () => void
}

export function ProfileScreen({ user, onBack }: ProfileScreenProps) {
  const { t } = useLanguage()

  return (
    <div className="h-full overflow-y-auto">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-white/20 backdrop-blur-xl border-b border-white/30 pt-6">
        <div className="flex items-center justify-between p-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={onBack}
            className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
          >
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <h1 className="font-semibold text-gray-800 text-sm">{t("profile.title")}</h1>
          <div className="flex space-x-1">
            <LanguageToggle />
            <Button
              variant="ghost"
              size="sm"
              className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
            >
              <Settings className="w-3 h-3" />
            </Button>
          </div>
        </div>
      </div>

      <div className="p-3 space-y-4">
        {/* Información del usuario */}
        <Card className="p-4 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
          <Avatar className="w-16 h-16 mx-auto mb-3 border-4 border-white/50">
            <AvatarImage src={user.avatar || "/placeholder.svg"} />
            <AvatarFallback className="text-lg">{user.name.charAt(0)}</AvatarFallback>
          </Avatar>
          <h2 className="text-lg font-bold text-gray-800 mb-1">{user.name}</h2>
          <p className="text-gray-600 text-sm mb-3">{user.email}</p>
          <Badge className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white text-xs">
            <Trophy className="w-2 h-2 mr-1" />
            {t("profile.premiumUser")}
          </Badge>
        </Card>

        {/* Estadísticas */}
        <div className="grid grid-cols-2 gap-3">
          <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
            <Gift className="w-6 h-6 mx-auto mb-2 text-blue-500" />
            <p className="text-xl font-bold text-gray-800">47</p>
            <p className="text-xs text-gray-600">{t("profile.couponsRedeemed")}</p>
          </Card>
          <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
            <Star className="w-6 h-6 mx-auto mb-2 text-yellow-500" />
            <p className="text-xl font-bold text-gray-800">4.9</p>
            <p className="text-xs text-gray-600">{t("profile.averageRating")}</p>
          </Card>
        </div>

        {/* Lugares favoritos */}
        <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30">
          <h3 className="font-semibold text-gray-800 mb-2 flex items-center text-sm">
            <MapPin className="w-4 h-4 mr-2 text-red-500" />
            {t("profile.favoritePlaces")}
          </h3>
          <div className="space-y-2">
            <div className="flex items-center justify-between p-2 bg-white/20 rounded-lg">
              <span className="text-gray-700 text-sm">Bariloche, Río Negro</span>
              <Badge variant="secondary" className="text-xs">
                8 {t("profile.visits")}
              </Badge>
            </div>
            <div className="flex items-center justify-between p-2 bg-white/20 rounded-lg">
              <span className="text-gray-700 text-sm">Mendoza, Argentina</span>
              <Badge variant="secondary" className="text-xs">
                12 {t("profile.visits")}
              </Badge>
            </div>
            <div className="flex items-center justify-between p-2 bg-white/20 rounded-lg">
              <span className="text-gray-700 text-sm">Las Leñas, Mendoza</span>
              <Badge variant="secondary" className="text-xs">
                3 {t("profile.visits")}
              </Badge>
            </div>
          </div>
        </Card>

        {/* Opciones del menú */}
        <div className="space-y-2">
          <Button
            variant="ghost"
            className="w-full justify-start h-10 bg-white/20 backdrop-blur-xl border border-white/30 text-gray-700 text-sm"
          >
            <Gift className="w-4 h-4 mr-3" />
            {t("profile.savedCoupons")}
          </Button>

          <Button
            variant="ghost"
            className="w-full justify-start h-10 bg-white/20 backdrop-blur-xl border border-white/30 text-gray-700 text-sm"
          >
            <Star className="w-4 h-4 mr-3" />
            {t("profile.reviewHistory")}
          </Button>

          <Button
            variant="ghost"
            className="w-full justify-start h-10 bg-white/20 backdrop-blur-xl border border-white/30 text-gray-700 text-sm"
          >
            <Settings className="w-4 h-4 mr-3" />
            {t("profile.settings")}
          </Button>

          <Button
            variant="ghost"
            className="w-full justify-start h-10 bg-white/20 backdrop-blur-xl border border-white/30 text-gray-700 text-sm"
          >
            <HelpCircle className="w-4 h-4 mr-3" />
            {t("profile.help")}
          </Button>
        </div>

        {/* Botón de cerrar sesión */}
        <Button
          variant="outline"
          className="w-full h-10 bg-red-50/50 border-red-200 text-red-600 hover:bg-red-100/50 rounded-xl text-sm mb-4"
        >
          <LogOut className="w-4 h-4 mr-2" />
          {t("profile.logout")}
        </Button>
      </div>
    </div>
  )
}
