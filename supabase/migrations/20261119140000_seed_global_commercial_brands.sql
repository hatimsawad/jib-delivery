-- Seed a starter directory of global and Moroccan commercial brands.
-- These are catalog records only: no store branch, partnership, price list, or logo is implied.
-- New records remain pending verification until a JIB admin reviews them.

insert into public.commercial_brands
  (name, normalized_name, slug, category, website_url, country_code, status, source_name, source_url, source_license)
values
  ('Marjane','marjane','marjane','grocery','https://www.marjane.ma','MA','pending_verification','Official website','https://www.marjane.ma','Brand name and public URL metadata only'),
  ('Carrefour','carrefour','carrefour','grocery','https://www.carrefour.com','FR','pending_verification','Official website','https://www.carrefour.com','Brand name and public URL metadata only'),
  ('Aswak Assalam','aswak assalam','aswak-assalam','grocery','https://www.aswakassalam.com','MA','pending_verification','Official website','https://www.aswakassalam.com','Brand name and public URL metadata only'),
  ('BIM','bim','bim','grocery','https://www.bim.ma','TR','pending_verification','Official website','https://www.bim.ma','Brand name and public URL metadata only'),
  ('Atacadão','atacadao','atacadao','grocery','https://www.atacadao.com.br','BR','pending_verification','Official website','https://www.atacadao.com.br','Brand name and public URL metadata only'),
  ('LabelVie','labelvie','labelvie','grocery','https://www.labelvie.ma','MA','pending_verification','Official website','https://www.labelvie.ma','Brand name and public URL metadata only'),
  ('McDonald''s','mcdonalds','mcdonalds','prepared-food','https://www.mcdonalds.com','US','pending_verification','Official website','https://www.mcdonalds.com','Brand name and public URL metadata only'),
  ('Burger King','burger king','burger-king','prepared-food','https://www.burgerking.com','US','pending_verification','Official website','https://www.burgerking.com','Brand name and public URL metadata only'),
  ('KFC','kfc','kfc','prepared-food','https://www.kfc.com','US','pending_verification','Official website','https://www.kfc.com','Brand name and public URL metadata only'),
  ('Pizza Hut','pizza hut','pizza-hut','prepared-food','https://www.pizzahut.com','US','pending_verification','Official website','https://www.pizzahut.com','Brand name and public URL metadata only'),
  ('Domino''s','dominos','dominos','prepared-food','https://www.dominos.com','US','pending_verification','Official website','https://www.dominos.com','Brand name and public URL metadata only'),
  ('Starbucks','starbucks','starbucks','beverages','https://www.starbucks.com','US','pending_verification','Official website','https://www.starbucks.com','Brand name and public URL metadata only'),
  ('Subway','subway','subway','prepared-food','https://www.subway.com','US','pending_verification','Official website','https://www.subway.com','Brand name and public URL metadata only'),
  ('Taco Bell','taco bell','taco-bell','prepared-food','https://www.tacobell.com','US','pending_verification','Official website','https://www.tacobell.com','Brand name and public URL metadata only'),
  ('Paul','paul','paul','bakery','https://www.paul.fr','FR','pending_verification','Official website','https://www.paul.fr','Brand name and public URL metadata only'),
  ('Dunkin''','dunkin','dunkin','beverages','https://www.dunkindonuts.com','US','pending_verification','Official website','https://www.dunkindonuts.com','Brand name and public URL metadata only'),
  ('IKEA','ikea','ikea','household','https://www.ikea.com','SE','pending_verification','Official website','https://www.ikea.com','Brand name and public URL metadata only'),
  ('Jumia','jumia','jumia','general-merchandise','https://www.jumia.ma','NG','pending_verification','Official website','https://www.jumia.ma','Brand name and public URL metadata only'),
  ('Miniso','miniso','miniso','general-merchandise','https://www.miniso.com','CN','pending_verification','Official website','https://www.miniso.com','Brand name and public URL metadata only'),
  ('Nike','nike','nike','fashion','https://www.nike.com','US','pending_verification','Official website','https://www.nike.com','Brand name and public URL metadata only'),
  ('Adidas','adidas','adidas','fashion','https://www.adidas.com','DE','pending_verification','Official website','https://www.adidas.com','Brand name and public URL metadata only'),
  ('Puma','puma','puma','fashion','https://www.puma.com','DE','pending_verification','Official website','https://www.puma.com','Brand name and public URL metadata only'),
  ('Zara','zara','zara','fashion','https://www.zara.com','ES','pending_verification','Official website','https://www.zara.com','Brand name and public URL metadata only'),
  ('H&M','h and m','hm','fashion','https://www.hm.com','SE','pending_verification','Official website','https://www.hm.com','Brand name and public URL metadata only'),
  ('LC Waikiki','lc waikiki','lc-waikiki','fashion','https://www.lcwaikiki.com','TR','pending_verification','Official website','https://www.lcwaikiki.com','Brand name and public URL metadata only'),
  ('Kiabi','kiabi','kiabi','fashion','https://www.kiabi.com','FR','pending_verification','Official website','https://www.kiabi.com','Brand name and public URL metadata only'),
  ('Decathlon','decathlon','decathlon','sports-outdoors','https://www.decathlon.com','FR','pending_verification','Official website','https://www.decathlon.com','Brand name and public URL metadata only'),
  ('Apple','apple','apple','electronics','https://www.apple.com','US','pending_verification','Official website','https://www.apple.com','Brand name and public URL metadata only'),
  ('Samsung','samsung','samsung','electronics','https://www.samsung.com','KR','pending_verification','Official website','https://www.samsung.com','Brand name and public URL metadata only'),
  ('Xiaomi','xiaomi','xiaomi','electronics','https://www.mi.com','CN','pending_verification','Official website','https://www.mi.com','Brand name and public URL metadata only'),
  ('Huawei','huawei','huawei','electronics','https://www.huawei.com','CN','pending_verification','Official website','https://www.huawei.com','Brand name and public URL metadata only'),
  ('Sony','sony','sony','electronics','https://www.sony.com','JP','pending_verification','Official website','https://www.sony.com','Brand name and public URL metadata only'),
  ('LG','lg','lg','electronics','https://www.lg.com','KR','pending_verification','Official website','https://www.lg.com','Brand name and public URL metadata only'),
  ('HP','hp','hp','electronics','https://www.hp.com','US','pending_verification','Official website','https://www.hp.com','Brand name and public URL metadata only'),
  ('Dell','dell','dell','electronics','https://www.dell.com','US','pending_verification','Official website','https://www.dell.com','Brand name and public URL metadata only'),
  ('Lenovo','lenovo','lenovo','electronics','https://www.lenovo.com','CN','pending_verification','Official website','https://www.lenovo.com','Brand name and public URL metadata only'),
  ('L''Oréal','loreal','loreal','beauty','https://www.loreal.com','FR','pending_verification','Official website','https://www.loreal.com','Brand name and public URL metadata only'),
  ('Sephora','sephora','sephora','beauty','https://www.sephora.com','FR','pending_verification','Official website','https://www.sephora.com','Brand name and public URL metadata only'),
  ('Yves Rocher','yves rocher','yves-rocher','beauty','https://www.yves-rocher.com','FR','pending_verification','Official website','https://www.yves-rocher.com','Brand name and public URL metadata only'),
  ('Nivea','nivea','nivea','personal-care','https://www.nivea.com','DE','pending_verification','Official website','https://www.nivea.com','Brand name and public URL metadata only'),
  ('Garnier','garnier','garnier','personal-care','https://www.garnier.com','FR','pending_verification','Official website','https://www.garnier.com','Brand name and public URL metadata only'),
  ('Philips','philips','philips','electronics','https://www.philips.com','NL','pending_verification','Official website','https://www.philips.com','Brand name and public URL metadata only'),
  ('Bosch','bosch','bosch','household','https://www.bosch.com','DE','pending_verification','Official website','https://www.bosch.com','Brand name and public URL metadata only'),
  ('P&G','procter and gamble','pg','personal-care','https://www.pg.com','US','pending_verification','Official website','https://www.pg.com','Brand name and public URL metadata only'),
  ('Nestlé','nestle','nestle','grocery','https://www.nestle.com','CH','pending_verification','Official website','https://www.nestle.com','Brand name and public URL metadata only'),
  ('Coca-Cola','coca cola','coca-cola','beverages','https://www.coca-colacompany.com','US','pending_verification','Official website','https://www.coca-colacompany.com','Brand name and public URL metadata only'),
  ('Pepsi','pepsi','pepsi','beverages','https://www.pepsi.com','US','pending_verification','Official website','https://www.pepsi.com','Brand name and public URL metadata only'),
  ('Danone','danone','danone','grocery','https://www.danone.com','FR','pending_verification','Official website','https://www.danone.com','Brand name and public URL metadata only'),
  ('Unilever','unilever','unilever','personal-care','https://www.unilever.com','GB','pending_verification','Official website','https://www.unilever.com','Brand name and public URL metadata only'),
  ('LEGO','lego','lego','toys-games','https://www.lego.com','DK','pending_verification','Official website','https://www.lego.com','Brand name and public URL metadata only'),
  ('Mattel','mattel','mattel','toys-games','https://www.mattel.com','US','pending_verification','Official website','https://www.mattel.com','Brand name and public URL metadata only')
on conflict (slug) do nothing;

insert into public.commercial_brand_aliases (brand_id, locale, alias, normalized_alias)
select b.id, a.locale, a.alias, a.normalized_alias
from public.commercial_brands b
cross join lateral (values
  ('ar', case b.slug
    when 'marjane' then 'مرجان' when 'carrefour' then 'كارفور'
    when 'aswak-assalam' then 'أسواق السلام' when 'mcdonalds' then 'ماكدونالدز'
    when 'burger-king' then 'برغر كينغ' when 'kfc' then 'كنتاكي'
    when 'pizza-hut' then 'بيتزا هت' when 'dominos' then 'دومينوز'
    when 'starbucks' then 'ستاربكس' when 'ikea' then 'إيكيا'
    when 'jumia' then 'جوميا' when 'nike' then 'نايكي'
    when 'adidas' then 'أديداس' when 'zara' then 'زارا'
    when 'apple' then 'آبل' when 'samsung' then 'سامسونغ'
    when 'xiaomi' then 'شاومي' when 'huawei' then 'هواوي'
    when 'sony' then 'سوني' when 'lg' then 'إل جي'
    when 'coca-cola' then 'كوكا كولا' when 'pepsi' then 'بيبسي'
    else null end),
  ('fr', case b.slug
    when 'marjane' then 'Marjane' when 'carrefour' then 'Carrefour'
    when 'aswak-assalam' then 'Aswak Assalam' when 'mcdonalds' then 'McDonald''s'
    when 'burger-king' then 'Burger King' when 'kfc' then 'KFC'
    when 'starbucks' then 'Starbucks' when 'ikea' then 'IKEA'
    else null end)
) as a(locale, alias)
where a.alias is not null
on conflict (brand_id, locale, normalized_alias) do nothing;
