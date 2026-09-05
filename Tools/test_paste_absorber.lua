-- Banc hors-jeu pour W.AttachPasteAbsorber.
-- Extrait la fonction de Widgets.lua et la fait tourner contre une EditBox
-- factice qui reproduit le plafonnement SetMaxBytes et la rafale OnChar.

local src = assert(io.open("TomoMod_Options/Config/Widgets.lua")):read("*a")
local fn = src:match("(function W%.AttachPasteAbsorber.-\nend)\n?$")
assert(fn, "AttachPasteAbsorber introuvable")

local W = {}
assert(loadstring("local W = ...\n" .. fn))(W)

-- ---- EditBox factice -------------------------------------------------
local function MakeBox()
  local b = {text="", maxBytes=0, scripts={}, hooks={}}
  function b:SetMaxLetters() end
  function b:SetMaxBytes(n) self.maxBytes = n end
  function b:GetText() return self.text end
  function b:SetCursorPosition() end
  function b:SetScript(k,f) self.scripts[k]=f end
  function b:HookScript(k,f) self.hooks[k]=self.hooks[k] or {}; table.insert(self.hooks[k],f) end
  function b:SetText(t)
    self.text = t
    for _,f in ipairs(self.hooks.OnTextChanged or {}) do f(self,false) end
  end
  -- Simule une frappe/collage : le moteur applique le plafond d'octets,
  -- puis emet OnChar pour chaque caractere reellement livre.
  function b:Type(s, deliverAll)
    for i=1,#s do
      local c = s:sub(i,i)
      if self.maxBytes == 0 or #self.text < self.maxBytes then
        self.text = self.text .. c
        for _,f in ipairs(self.hooks.OnTextChanged or {}) do f(self,true) end
      end
      if deliverAll ~= false then
        for _,f in ipairs(self.hooks.OnChar or {}) do f(self,c) end
      end
    end
  end
  function b:Frame(n)
    for _=1,(n or 1) do if self.scripts.OnUpdate then self.scripts.OnUpdate(self) end end
  end
  return b
end

local pass, fail = 0, 0
local function check(name, cond)
  if cond then pass=pass+1; print("  ok   "..name)
  else fail=fail+1; print("  FAIL "..name) end
end

-- 1) Gros collage : la boite ne garde qu'un resume, le buffer a tout.
do
  local box, settled = MakeBox(), nil
  local h = W.AttachPasteAbsorber(box, {
    summary = function(n) return "[cap "..n.."]" end,
    onSettled = function(t) settled = t end,
  })
  local big = string.rep("A", 50000)
  box:Type(big)
  box:Frame(2)
  check("gros collage capture entierement", h.GetText() == big)
  check("boite allegee", #box:GetText() < 100)
  check("onSettled recoit la chaine complete", settled == big)
  check("IsCaptured vrai", h.IsCaptured() == true)
end

-- 2) Chaine courte : chemin d'avant, aucune capture.
do
  local box, settled = MakeBox(), nil
  local h = W.AttachPasteAbsorber(box, { onSettled = function(t) settled = t end })
  box:Type("  petite  ")
  box:Frame(2)
  check("chaine courte non capturee", h.IsCaptured() == false)
  check("GetText trim la boite", h.GetText() == "petite")
  check("onSettled tire aussi pour le court", settled ~= nil)
end

-- 3) Collage non livre a OnChar : le plafond est leve, onRetry tire.
do
  local box, retried = MakeBox(), false
  local h = W.AttachPasteAbsorber(box, { cap = 32, onRetry = function() retried = true end })
  box:Type(string.rep("B", 200), false)
  box:Type("C"); box:Frame(2)
  check("plafond leve apres echec", box.maxBytes == 0)
  check("onRetry tire", retried == true)
  check("aucune capture partielle", h.IsCaptured() == false)
end

-- 4) Edition manuelle apres capture : la capture est abandonnee.
do
  local box = MakeBox()
  local h = W.AttachPasteAbsorber(box, { summary = function(n) return "[cap]" end })
  box:Type(string.rep("D", 50000)); box:Frame(2)
  assert(h.IsCaptured())
  box:Type("x")
  box:Frame(2)
  check("capture abandonnee apres frappe", h.IsCaptured() == false)
end

-- 4b) Client qui signale SetText comme saisie utilisateur : le garde
-- settingText doit empecher notre propre resume d'annuler la capture.
do
  local box = MakeBox()
  function box:SetText(t)
    self.text = t
    for _,f in ipairs(self.hooks.OnTextChanged or {}) do f(self,true) end
  end
  local h = W.AttachPasteAbsorber(box, { summary = function() return "[cap]" end })
  box:Type(string.rep("F", 50000)); box:Frame(2)
  check("capture survit a un SetText signale saisie", h.IsCaptured() == true)
end

-- 4c) Rafale etalee sur plusieurs frames : Finalize ne doit pas conclure
-- tant que des caracteres continuent d'arriver.
do
  local box = MakeBox()
  local h = W.AttachPasteAbsorber(box, { summary = function(n) return "[cap "..n.."]" end })
  local part = string.rep("G", 20000)
  box:Type(part)
  box:Frame(1)
  box:Type(part)
  box:Frame(1)
  box:Frame(1)
  check("rafale multi-frames capturee en entier", h.GetText() == part .. part)
end

-- 4d) Effacement au clavier apres capture. Retour arriere et Suppr emettent
-- OnTextChanged sans passer par OnChar : sans le garde, la capture survivrait
-- a l'ecran vide et le joueur importerait la chaine precedente.
do
  local box = MakeBox()
  local h = W.AttachPasteAbsorber(box, { summary = function() return "[cap]" end })
  box:Type(string.rep("H", 50000)); box:Frame(2)
  assert(h.IsCaptured(), "pre-condition: capture en place")
  box.text = box.text:sub(1, -2)
  for _,f in ipairs(box.hooks.OnTextChanged or {}) do f(box, true) end
  check("capture abandonnee apres effacement clavier", h.IsCaptured() == false)
  check("GetText retombe sur la boite", h.GetText() == "[cap")
end

-- 5) Clear remet a zero sans relancer onSettled.
do
  local box, n = MakeBox(), 0
  local h = W.AttachPasteAbsorber(box, {
    summary = function() return "[cap]" end,
    onSettled = function() n = n + 1 end,
  })
  box:Type(string.rep("E", 50000)); box:Frame(2)
  local before = n
  h.Clear()
  check("Clear vide la boite", box:GetText() == "")
  check("Clear abandonne la capture", h.IsCaptured() == false)
  check("Clear ne rejoue pas onSettled", n == before)
end

print(string.format("\n%d ok, %d echecs", pass, fail))
os.exit(fail == 0 and 0 or 1)
