"use client"

import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, MapPin, Calendar, Clock, Share2, Heart, Mountain, Wine } from "lucide-react"
import { useLanguage } from "@/contexts/language-context"
import { LanguageToggle } from "@/components/language-toggle"
import Image from "next/image"

interface CouponDetailProps {
  coupon: any
  onBack: () => void
}

export function CouponDetail({ coupon, onBack }: CouponDetailProps) {
  const { t } = useLanguage()

  return (
    <div className="h-full overflow-y-auto">
      {/* Header con botón de regreso */}
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
          <h1 className="font-semibold text-gray-800 text-sm">{t("detail.title")}</h1>
          <div className="flex space-x-1">
            <LanguageToggle />
            <Button
              variant="ghost"
              size="sm"
              className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
            >
              <Share2 className="w-3 h-3" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-xl border border-white/30"
            >
              <Heart className="w-3 h-3" />
            </Button>
          </div>
        </div>
      </div>

      {/* Imagen principal */}
      <div className="relative">
        <Image
          src={coupon.image || "/placeholder.svg"}
          alt={coupon.title}
          width={400}
          height={200}
          className="w-full h-48 object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
        <div className="absolute bottom-3 left-3 right-3">
          <div className="flex items-center justify-between">
            <Badge
              className={`${
                coupon.category === "Nieve" ? "bg-blue-500/80 text-white" : "bg-purple-500/80 text-white"
              } backdrop-blur-sm text-xs`}
            >
              {coupon.category === "Nieve" ? <Mountain className="w-2 h-2 mr-1" /> : <Wine className="w-2 h-2 mr-1" />}
              {coupon.category === "Nieve" ? t("home.snow") : t("home.wine")}
            </Badge>
            <Badge className="bg-red-500/90 text-white font-bold px-3 py-1 text-sm backdrop-blur-sm">
              {coupon.discount}
            </Badge>
          </div>
        </div>
      </div>

      <div className="p-3 space-y-4">
        {/* Información principal */}
        <div>
          <h1 className="text-xl font-bold text-gray-800 mb-2">{coupon.title}</h1>
          <p className="text-gray-600 text-sm leading-relaxed">{coupon.description}</p>
        </div>

        {/* Información de ubicación y fecha */}
        <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30">
          <div className="space-y-2">
            <div className="flex items-center text-gray-700 text-sm">
              <MapPin className="w-4 h-4 mr-2 text-blue-500" />
              <span className="font-medium">{coupon.location}</span>
            </div>
            <div className="flex items-center text-gray-700 text-sm">
              <Calendar className="w-4 h-4 mr-2 text-green-500" />
              <span>
                {t("detail.validUntil")} {coupon.validUntil}
              </span>
            </div>
            <div className="flex items-center text-gray-700 text-sm">
              <Clock className="w-4 h-4 mr-2 text-orange-500" />
              <span>{t("detail.available")}</span>
            </div>
          </div>
        </Card>

        {/* Precios */}
        <Card className="p-4 bg-gradient-to-r from-green-50/50 to-blue-50/50 backdrop-blur-xl border border-white/30">
          <div className="text-center space-y-1">
            <p className="text-xs text-gray-600">{t("detail.originalPrice")}</p>
            <p className="text-lg text-gray-500 line-through">{coupon.originalPrice}</p>
            <p className="text-xs text-green-600 font-medium">{t("detail.discountPrice")}</p>
            <p className="text-2xl font-bold text-green-600">{coupon.discountedPrice}</p>
            <p className="text-xs text-gray-600">
              {t("detail.youSave")}{" "}
              <span className="font-bold text-red-500">
                $
                {Number.parseInt(coupon.originalPrice.replace(/[$.]/g, "")) -
                  Number.parseInt(coupon.discountedPrice.replace(/[$.]/g, ""))}
              </span>
            </p>
          </div>
        </Card>

        {/* Código QR */}
        <Card className="p-4 bg-white/30 backdrop-blur-xl border border-white/40 text-center">
          <h3 className="font-bold text-sm text-gray-800 mb-3">{t("detail.qrTitle")}</h3>
          <div className="flex justify-center mb-3">
            <div className="p-3 bg-white rounded-xl shadow-lg">
              <Image
                src={coupon.qrCode || "/placeholder.svg"}
                alt="Código QR"
                width={120}
                height={120}
                className="w-24 h-24"
              />
            </div>
          </div>
          <p className="text-xs text-gray-600 mb-3">{t("detail.qrDescription")}</p>
          <div className="bg-gray-100 rounded-lg p-2 font-mono text-xs text-gray-700">
            FULLDAYGO-{coupon.id}-{coupon.category.toUpperCase()}-2024
          </div>
        </Card>

        {/* Términos y condiciones */}
        <Card className="p-3 bg-white/20 backdrop-blur-xl border border-white/30">
          <h4 className="font-semibold text-gray-800 mb-2 text-sm">{t("detail.terms")}</h4>
          <ul className="text-xs text-gray-600 space-y-1">
            <li>{t("detail.term1")}</li>
            <li>{t("detail.term2")}</li>
            <li>{t("detail.term3")}</li>
            <li>{t("detail.term4")}</li>
            <li>{t("detail.term5")}</li>
          </ul>
        </Card>

        {/* Botones de acción */}
        <div className="space-y-2 pb-4">
          <Button className="w-full h-11 bg-gradient-to-r from-blue-500 to-purple-500 text-white font-semibold rounded-xl text-sm">
            {t("detail.useNow")}
          </Button>
          <Button
            variant="outline"
            className="w-full h-11 bg-white/20 backdrop-blur-xl border border-white/40 text-gray-700 rounded-xl text-sm"
          >
            {t("detail.share")}
          </Button>
        </div>
      </div>
    </div>
  )
}
