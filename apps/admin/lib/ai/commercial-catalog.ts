export type CommercialCategory =
  | "prepared-food"
  | "bakery"
  | "beverages"
  | "grocery"
  | "fresh-produce"
  | "meat-seafood"
  | "household"
  | "personal-care"
  | "electronics"
  | "fashion"
  | "beauty"
  | "flowers-gifts"
  | "toys-games"
  | "books-stationery"
  | "pet-supplies"
  | "sports-outdoors"
  | "automotive"
  | "pharmacy"
  | "general-merchandise";

type CategoryProfile = {
  id: CommercialCategory;
  aliases: string[];
  visualRules: string;
};

const categories: CategoryProfile[] = [
  { id:"prepared-food", aliases:["burger","hamburger","pizza","sandwich","tacos","taco","tajine","tagine","couscous","pasta","salad","meal","وجبة","برغر","همبرغر","بيتزا","ساندويتش","شطيرة","طاجين","كسكس","تاكوس","طاكوس","سوشي","دجاج مقلي","fried chicken","kfc","mcdonalds","ماكدونالدز"], visualRules:"Show the actual prepared dish ready to eat, using only the named ingredients and supplied preparation details. Use an appropriate plate, tray, cup or food wrapper for the item. Never show a cook, person, kitchen, restaurant interior, or ingredients-only scene." },
  { id:"bakery", aliases:["bread","croissant","cake","pastry","donut","muffin","خبز","كرواسون","كيك","كعك","حلويات","معجنات","فطيرة"], visualRules:"Show the exact baked product with realistic crumb, crust, layers and scale. Do not substitute a different pastry or add fillings/toppings not specified." },
  { id:"beverages", aliases:["water","juice","soda","coffee","tea","milk","drink","ماء","عصير","مشروب","قهوة","شاي","حليب","مشروبات"], visualRules:"Show the exact beverage in a suitable clean glass, cup, bottle or can. Preserve the provided packaging and liquid appearance; do not invent a brand label or text." },
  { id:"grocery", aliases:["rice","oil","sugar","flour","pasta","cereal","canned","أرز","زيت","سكر","دقيق","معلبات","مواد غذائية"], visualRules:"Show the exact grocery item or package, with realistic size and material. Preserve package design only when an authorized reference image is provided; never invent readable label text." },
  { id:"fresh-produce", aliases:["apple","banana","orange","tomato","potato","onion","lettuce","تفاح","موز","برتقال","طماطم","بطاطس","بصل","خضر","فواكه","خضروات"], visualRules:"Show only the exact fresh produce requested, with believable natural shape, color and quantity. Avoid unrelated produce and decorative food scenes." },
  { id:"meat-seafood", aliases:["beef","chicken","lamb","fish","shrimp","salmon","لحم","دجاج","غنم","سمك","روبيان","قمرون","مأكولات بحرية"], visualRules:"Show the exact cut or species, raw or cooked according to the product description. Do not substitute species, cuts or preparation state." },
  { id:"household", aliases:["detergent","cleaner","tissue","paper towel","dish soap","منظف","مسحوق","مناديل","صابون الأواني","أدوات منزلية"], visualRules:"Show the exact household product as a clean commercial product photograph on a neutral background. No people, rooms or staged lifestyle scenes." },
  { id:"personal-care", aliases:["shampoo","toothpaste","soap","deodorant","toothbrush","شامبو","معجون أسنان","صابون","مزيل عرق","فرشاة أسنان"], visualRules:"Show the exact personal-care item and its real container form. Do not invent brand marks, claims, ingredients or label text." },
  { id:"electronics", aliases:["phone","smartphone","laptop","tablet","headphones","charger","television","هاتف","حاسوب","لوحي","سماعات","شاحن","تلفاز","إلكترونيات"], visualRules:"Show the exact device type, recognizable physical design, ports and accessories only when specified. Neutral studio product photography, no fabricated logos, screens full of text or extra accessories." },
  { id:"fashion", aliases:["shirt","dress","shoes","sneakers","jacket","pants","قميص","فستان","حذاء","أحذية","سترة","ملابس","أزياء"], visualRules:"Show the exact garment or footwear, preserving stated color, cut, material and pattern. Use a clean catalog view; do not add models or accessories unless explicitly requested." },
  { id:"beauty", aliases:["perfume","makeup","lipstick","cream","serum","عطر","مكياج","أحمر شفاه","كريم","سيروم","تجميل"], visualRules:"Show the exact beauty product container and product form, clean premium studio lighting. Never fabricate logos, claims, ingredients or readable package text." },
  { id:"flowers-gifts", aliases:["flowers","bouquet","gift","roses","زهور","ورود","باقة","هدية"], visualRules:"Show the exact bouquet or gift arrangement, matching named flower types, colors and count where supplied. Do not add unrelated gift items." },
  { id:"toys-games", aliases:["toy","doll","puzzle","board game","لعبة","دمية","أحجية","ألعاب"], visualRules:"Show the exact toy or game and its included components only. Keep proportions, colors and packaging realistic; no children or people." },
  { id:"books-stationery", aliases:["book","notebook","pen","paper","كتاب","دفتر","قلم","قرطاسية"], visualRules:"Show the exact book or stationery item, with cover art only from supplied authorized references. Do not invent titles, authors or readable text." },
  { id:"pet-supplies", aliases:["pet food","cat litter","dog leash","طعام الحيوانات","رمل القطط","مستلزمات الحيوانات"], visualRules:"Show the exact pet supply product or package. Do not add animals unless the item itself is an animal-related accessory that requires scale context." },
  { id:"sports-outdoors", aliases:["ball","bicycle","helmet","fitness","كرة","دراجة","خوذة","رياضة","تخييم"], visualRules:"Show the exact sports or outdoor equipment, matching materials, dimensions and accessories specified." },
  { id:"automotive", aliases:["tire","motor oil","car accessory","tyre","إطار","زيت محرك","إكسسوارات السيارات","قطع غيار"], visualRules:"Show the exact automotive part or accessory with realistic shape, finish and scale; no vehicle or unrelated components unless needed to identify the part." },
  { id:"pharmacy", aliases:["first aid","bandage","medical device","thermometer","ضمادات","إسعافات أولية","جهاز طبي","ميزان حرارة","صيدلية"], visualRules:"Show only the exact non-prescription retail item or medical device. Do not imply treatment effects, invent dosage or claims, or depict prescription medicines as recommendations." },
];

function normalize(value: string): string {
  return value.toLocaleLowerCase().normalize("NFKD")
    .replace(/[\u064B-\u065F\u0670\u0640]/g, "")
    .replace(/[أإآٱ]/g, "ا").replace(/ى/g, "ي").replace(/ة/g, "ه")
    .replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

export function detectCommercialCategory(value: string): CommercialCategory {
  const text = normalize(value);
  for (const category of categories) {
    if (category.aliases.some(alias => {
      const key = normalize(alias);
      return text === key || text.includes(key);
    })) return category.id;
  }
  return "general-merchandise";
}

export function buildCommercialProductPrompt(title: string, description: string): string {
  const source = `${title} ${description}`;
  const category = detectCommercialCategory(source);
  const profile = categories.find(item => item.id === category);
  const dish = buildMoroccanDishPrompt(source);
  const foodCategory = category === "prepared-food" || category === "bakery" ||
    category === "beverages" || category === "fresh-produce" || category === "meat-seafood";
  const base = [
    "JIB UNIVERSAL COMMERCIAL CATALOG IMAGE STANDARD.",
    `Exact product name: ${title.trim()}.`,
    `Merchant-supplied product details: ${description.trim()}.`,
    `Catalog category: ${category}.`,
    "The image must depict the exact sellable product itself, not a person, shop, restaurant, kitchen, room, advertisement, collage, or lifestyle scene.",
    "Match the named item, variant, color, size, material, quantity, condition, preparation state and packaging only to the extent stated in the product data or visible in an authorized reference.",
    profile?.visualRules ?? "Show one clearly identifiable exact retail product, centered, with realistic proportions and materials, on a clean neutral studio background.",
    "Premium photorealistic e-commerce catalog photography, one product or one serving, centered composition, sharp detail, balanced natural studio lighting, clean neutral background, square 1:1.",
    "Do not fabricate brand logos, trademarks, package text, certification marks, ingredients, health claims, accessories, or product features. Do not add unrelated objects. No watermark or decorative typography.",
  ];
  if (dish) base.unshift(dish);
  if (foodCategory) base.push("Food and beverage products only: make the actual food or drink the hero subject, appetizing but faithful to the real item; never substitute a different dish.");
  return base.join(" ").slice(0, 2048);
}

import { buildMoroccanDishPrompt } from "./moroccan-dishes";
