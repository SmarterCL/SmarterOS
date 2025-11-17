"use client"

import { createContext, useContext, useState, type ReactNode } from "react"

type Language = "es" | "en"

interface LanguageContextType {
  language: Language
  setLanguage: (lang: Language) => void
  t: (key: string) => string
}

const translations = {
  es: {
    // Login Screen
    "login.title": "FulldayGO",
    "login.subtitle": "Tu compañero perfecto para aventuras de esquí y experiencias únicas en Argentina",
    "login.welcome": "Bienvenido",
    "login.description": "Inicia sesión para acceder a tus cupones exclusivos",
    "login.continueGoogle": "Continuar con Google",
    "login.terms": "Al continuar, aceptas nuestros términos y condiciones",

    // Home Screen
    "home.hello": "Hola",
    "home.subtitle": "Descubre aventuras increíbles",
    "home.search": "Buscar cupones...",
    "home.activeCoupons": "Cupones activos",
    "home.usedThisMonth": "Usados este mes",
    "home.saved": "Ahorrado",
    "home.snow": "Nieve",
    "home.wine": "Vinos",
    "home.viewCoupon": "Ver cupón",

    // Coupon Detail
    "detail.title": "Detalle del Cupón",
    "detail.validUntil": "Válido hasta",
    "detail.available": "Disponible 24/7",
    "detail.originalPrice": "Precio original",
    "detail.discountPrice": "Tu precio con descuento",
    "detail.youSave": "Ahorras:",
    "detail.qrTitle": "Código QR para canjear",
    "detail.qrDescription": "Presenta este código QR en el establecimiento para aplicar tu descuento",
    "detail.terms": "Términos y Condiciones",
    "detail.term1": "• Válido solo para una persona por cupón",
    "detail.term2": "• No acumulable con otras promociones",
    "detail.term3": "• Sujeto a disponibilidad",
    "detail.term4": "• Reserva previa requerida",
    "detail.term5": "• No reembolsable",
    "detail.useNow": "Usar Cupón Ahora",
    "detail.share": "Compartir con Amigos",

    // Profile Screen
    "profile.title": "Mi Perfil",
    "profile.premiumUser": "Usuario Premium",
    "profile.couponsRedeemed": "Cupones canjeados",
    "profile.averageRating": "Calificación promedio",
    "profile.favoritePlaces": "Lugares Favoritos",
    "profile.visits": "visitas",
    "profile.savedCoupons": "Mis Cupones Guardados",
    "profile.reviewHistory": "Historial de Reseñas",
    "profile.settings": "Configuración",
    "profile.help": "Ayuda y Soporte",
    "profile.logout": "Cerrar Sesión",

    // Coupons
    "coupon.skiing.title": "Esquí en Cerro Catedral",
    "coupon.skiing.description": "Descuento del 25% en pases de esquí para toda la familia en Bariloche",
    "coupon.skiing.location": "Bariloche, Río Negro",

    "coupon.winery.title": "Bodega Catena Zapata",
    "coupon.winery.description": "Tour premium con degustación de vinos Malbec y almuerzo gourmet",
    "coupon.winery.location": "Mendoza, Argentina",

    "coupon.lasLenas.title": "Las Leñas Ski Resort",
    "coupon.lasLenas.description": "Paquete completo: hospedaje + ski pass + clases para principiantes",
    "coupon.lasLenas.location": "Las Leñas, Mendoza",

    "coupon.wineRoute.title": "Ruta del Vino Maipú",
    "coupon.wineRoute.description": "Recorrido en bicicleta por 3 bodegas boutique con almuerzo incluido",
    "coupon.wineRoute.location": "Maipú, Mendoza",
  },
  en: {
    // Login Screen
    "login.title": "FulldayGO",
    "login.subtitle": "Your perfect companion for ski adventures and unique experiences in Argentina",
    "login.welcome": "Welcome",
    "login.description": "Sign in to access your exclusive coupons",
    "login.continueGoogle": "Continue with Google",
    "login.terms": "By continuing, you accept our terms and conditions",

    // Home Screen
    "home.hello": "Hello",
    "home.subtitle": "Discover incredible adventures",
    "home.search": "Search coupons...",
    "home.activeCoupons": "Active coupons",
    "home.usedThisMonth": "Used this month",
    "home.saved": "Saved",
    "home.snow": "Snow",
    "home.wine": "Wine",
    "home.viewCoupon": "View coupon",

    // Coupon Detail
    "detail.title": "Coupon Details",
    "detail.validUntil": "Valid until",
    "detail.available": "Available 24/7",
    "detail.originalPrice": "Original price",
    "detail.discountPrice": "Your discounted price",
    "detail.youSave": "You save:",
    "detail.qrTitle": "QR Code to redeem",
    "detail.qrDescription": "Present this QR code at the establishment to apply your discount",
    "detail.terms": "Terms and Conditions",
    "detail.term1": "• Valid for one person per coupon only",
    "detail.term2": "• Not combinable with other promotions",
    "detail.term3": "• Subject to availability",
    "detail.term4": "• Prior reservation required",
    "detail.term5": "• Non-refundable",
    "detail.useNow": "Use Coupon Now",
    "detail.share": "Share with Friends",

    // Profile Screen
    "profile.title": "My Profile",
    "profile.premiumUser": "Premium User",
    "profile.couponsRedeemed": "Coupons redeemed",
    "profile.averageRating": "Average rating",
    "profile.favoritePlaces": "Favorite Places",
    "profile.visits": "visits",
    "profile.savedCoupons": "My Saved Coupons",
    "profile.reviewHistory": "Review History",
    "profile.settings": "Settings",
    "profile.help": "Help & Support",
    "profile.logout": "Sign Out",

    // Coupons
    "coupon.skiing.title": "Skiing at Cerro Catedral",
    "coupon.skiing.description": "25% discount on ski passes for the whole family in Bariloche",
    "coupon.skiing.location": "Bariloche, Río Negro",

    "coupon.winery.title": "Catena Zapata Winery",
    "coupon.winery.description": "Premium tour with Malbec wine tasting and gourmet lunch",
    "coupon.winery.location": "Mendoza, Argentina",

    "coupon.lasLenas.title": "Las Leñas Ski Resort",
    "coupon.lasLenas.description": "Complete package: accommodation + ski pass + beginner classes",
    "coupon.lasLenas.location": "Las Leñas, Mendoza",

    "coupon.wineRoute.title": "Maipú Wine Route",
    "coupon.wineRoute.description": "Bicycle tour through 3 boutique wineries with lunch included",
    "coupon.wineRoute.location": "Maipú, Mendoza",
  },
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined)

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [language, setLanguage] = useState<Language>("es")

  const t = (key: string): string => {
    return translations[language][key as keyof (typeof translations)[typeof language]] || key
  }

  return <LanguageContext.Provider value={{ language, setLanguage, t }}>{children}</LanguageContext.Provider>
}

export function useLanguage() {
  const context = useContext(LanguageContext)
  if (context === undefined) {
    throw new Error("useLanguage must be used within a LanguageProvider")
  }
  return context
}
