"use client"

import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Mountain, Wine, User, Bell, Search, MapPin, Calendar, Percent } from "lucide-react"
import { useLanguage } from "@/contexts/language-context"
import { LanguageToggle } from "@/components/language-toggle"
import Image from "next/image"

interface HomeScreenProps {
  user: any
  onCouponSelect: (coupon: any) => void
  onProfileOpen: () => void
}

export function HomeScreen({ user, onCouponSelect, onProfileOpen }: HomeScreenProps) {
  const { t } = useLanguage()

  const coupons = [
    {
      id: 1,
      titleKey: "coupon.skiing.title",
      descriptionKey: "coupon.skiing.description",
      locationKey: "coupon.skiing.location",
      discount: "25% OFF",
      validUntil: "31 Dic 2024",
      image: "/bariloche-skiing.png",
      category: "Nieve",
      originalPrice: "$15.000",
      discountedPrice: "$11.250",
      qrCode: "/qr-code.png",
    },
    {
      id: 2,
      titleKey: "coupon.winery.title",
      descriptionKey: "coupon.winery.description",
      locationKey: "coupon.winery.location",
      discount: "30% OFF",
      validUntil: "15 Ene 2025",
      image: "/mendoza-vineyard.png",
      category: "Vinos",
      originalPrice: "$8.500",
      discountedPrice: "$5.950",
      qrCode: "/qr-code.png",
    },
    {
      id: 3,
      titleKey: "coupon.lasLenas.title",
      descriptionKey: "coupon.lasLenas.description",
      locationKey: "coupon.lasLenas.location",
      discount: "40% OFF",
      validUntil: "30 Sep 2024",
      image: "/las-lenas-ski-resort.png",
      category: "Nieve",
      originalPrice: "$45.000",
      discountedPrice: "$27.000",
      qrCode: "/qr-code.png",
    },
    {
      id: 4,
      titleKey: "coupon.wineRoute.title",
      descriptionKey: "coupon.wineRoute.description",
      locationKey: "coupon.wineRoute.location",
      discount: "20% OFF",
      validUntil: "28 Feb 2025",
      image: "/mendoza-vineyard-bike-tour.png",
      category: "Vinos",
      originalPrice: "$12.000",
      discountedPrice: "$9.600",
      qrCode: "/qr-code.png",
    },
  ]

  return (
    <div className="h-full overflow-y-auto">
      {/* Header con efecto liquid glass */}
      <div className="sticky top-0 z-40 bg-white/20 backdrop-blur-xl border-b border-white/30 pt-6">
        <div className="flex items-center justify-between p-3">
          <div className="flex items-center space-x-2">
            <Avatar className="w-8 h-8 border-2 border-white/50">
              <AvatarImage src={user.avatar || "/placeholder.svg"} />
              <AvatarFallback className="text-xs">{user.name.charAt(0)}</AvatarFallback>
            </Avatar>
            <div>
              <p className="text-sm font-medium text-gray-800">
                {t("home.hello")}, {user.name.split(" ")[0]}
              </p>
              <p className="text-xs text-gray-600">{t("home.subtitle")}</p>
            </div>
          </div>
          <div className="flex items-center space-x-1">
            <LanguageToggle />
            <Button
              variant="ghost"
              size="sm"
              className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
            >
              <Bell className="w-3 h-3" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
              onClick={onProfileOpen}
            >
              <User className="w-3 h-3" />
            </Button>
          </div>
        </div>
      </div>

      <div className="p-3 space-y-4">
        {/* Barra de búsqueda */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-500" />
          <input
            type="text"
            placeholder={t("home.search")}
            className="w-full pl-10 pr-4 py-2.5 bg-white/30 backdrop-blur-xl border border-white/40 rounded-xl text-gray-800 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 text-sm"
          />
        </div>

        {/* Estadísticas */}
        <div className="grid grid-cols-3 gap-2">
          <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
            <Percent className="w-5 h-5 mx-auto mb-1 text-green-600" />
            <p className="text-lg font-bold text-gray-800">12</p>
            <p className="text-xs text-gray-600">{t("home.activeCoupons")}</p>
          </Card>
          <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
            <Calendar className="w-5 h-5 mx-auto mb-1 text-blue-600" />
            <p className="text-lg font-bold text-gray-800">5</p>
            <p className="text-xs text-gray-600">{t("home.usedThisMonth")}</p>
          </Card>
          <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30 text-center">
            <MapPin className="w-5 h-5 mx-auto mb-1 text-purple-600" />
            <p className="text-lg font-bold text-gray-800">$25K</p>
            <p className="text-xs text-gray-600">{t("home.saved")}</p>
          </Card>
        </div>

        {/* Filtros de categoría */}
        <div className="flex space-x-2">
          <Badge className="bg-blue-500/20 text-blue-700 border-blue-300/50 backdrop-blur-xl text-xs">
            <Mountain className="w-3 h-3 mr-1" />
            {t("home.snow")}
          </Badge>
          <Badge className="bg-purple-500/20 text-purple-700 border-purple-300/50 backdrop-blur-xl text-xs">
            <Wine className="w-3 h-3 mr-1" />
            {t("home.wine")}
          </Badge>
        </div>

        {/* Lista de cupones */}
        <div className="space-y-3 pb-4">
          {coupons.map((coupon) => (
            <Card
              key={coupon.id}
              className="overflow-hidden bg-white/20 backdrop-blur-xl border border-white/30 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer"
              onClick={() =>
                onCouponSelect({
                  ...coupon,
                  title: t(coupon.titleKey),
                  description: t(coupon.descriptionKey),
                  location: t(coupon.locationKey),
                })
              }
            >
              <div className="relative">
                <Image
                  src={coupon.image || "/placeholder.svg"}
                  alt={t(coupon.titleKey)}
                  width={400}
                  height={160}
                  className="w-full h-32 object-cover"
                />
                <div className="absolute top-2 right-2">
                  <Badge className="bg-red-500 text-white font-bold px-2 py-1 text-xs">{coupon.discount}</Badge>
                </div>
                <div className="absolute top-2 left-2">
                  <Badge
                    className={`${
                      coupon.category === "Nieve" ? "bg-blue-500/80 text-white" : "bg-purple-500/80 text-white"
                    } backdrop-blur-sm text-xs`}
                  >
                    {coupon.category === "Nieve" ? (
                      <Mountain className="w-2 h-2 mr-1" />
                    ) : (
                      <Wine className="w-2 h-2 mr-1" />
                    )}
                    {coupon.category === "Nieve" ? t("home.snow") : t("home.wine")}
                  </Badge>
                </div>
              </div>

              <div className="p-3">
                <h3 className="font-bold text-sm text-gray-800 mb-1">{t(coupon.titleKey)}</h3>
                <p className="text-gray-600 text-xs mb-2 line-clamp-2">{t(coupon.descriptionKey)}</p>

                <div className="flex items-center justify-between mb-2 text-xs">
                  <div className="flex items-center text-gray-500">
                    <MapPin className="w-2 h-2 mr-1" />
                    {t(coupon.locationKey)}
                  </div>
                  <div className="flex items-center text-gray-500">
                    <Calendar className="w-2 h-2 mr-1" />
                    {coupon.validUntil}
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-1">
                    <span className="text-sm font-bold text-green-600">{coupon.discountedPrice}</span>
                    <span className="text-xs text-gray-500 line-through">{coupon.originalPrice}</span>
                  </div>
                  <Button
                    size="sm"
                    className="bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-lg text-xs px-3 py-1"
                  >
                    {t("home.viewCoupon")}
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
