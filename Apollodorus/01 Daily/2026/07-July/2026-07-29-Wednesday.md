---
banner:
  - - WednesdayBanner.avif
banner-y: 50
banner-x: 30
content-start: 200
banner-display: cover
banner-repeat: true
banner-height: 400
banner-fade: -75
banner-radius: 25
cssclasses:
  - image-borders
  - image-small
  - timegarden-daily
  - wednesday
  - daily
date: 2026-07-29
alias: Diaatéquebom
dayRating: 8
tags: "#type/daily-note"
journal: daily
journal-date: 2026-07-29
journal-start-date: 2026-07-29
journal-end-date: 2026-07-29
aiAnswer: ""
---
# ✧ Wednesday, July 29, 2026
[[2026-W31|]]
`BUTTON[prev-day, current-week, next-day]`
```meta-bind-button
id: prev-day
class: phone-responsive
style: primary
label: ← Yesterday
hidden: true
actions:
  - type: open
    link: "[[/01 Daily/2026/07-July/2026-07-28-Tuesday]]"
    newTab: false
```
```meta-bind-button
id: current-week 
style: primary
class: phone-responsive
label: This Week
hidden: true
actions:
  - type: open
    link: "[[/02 Weekly/2026/2026-W31]]"
    newTab: false
```
```meta-bind-button
id: next-day
style: primary
class: phone-responsive
label: Tomorrow →
hidden: true
actions:
  - type: open
    link: "[[/01 Daily/2026/07-July/2026-07-30-Thursday]]"
    newTab: false
```

```meta-bind
INPUT[text(placeholder('Name your Day!'), class('custom-input')):alias]
```
---
- fiz porra nenhuma hoje, fiquei meio pá pq  queria estar realmente ajudando em algo, mas o Arthur disse pra eu ficar de boa que n tinha pq ficar me enchendo de trabalho (até pq tô de férias técnicamente). Amanhã vamos fazer carbonara com o pessoal, eu quero tentar tomar mais iniciativa nessa, ent vou tentar passar o dia vendo receita pra fazer (AH, TAMBÉM VAMOS TOMAR VINHO :D)
  
preciso ajeitar a mardita da minha receita pra dar um tchã a mais e funcionar pra tipo 5-6 pessoas, por aí
### <p hidden>PicturesEnd</p>
---
```meta-bind
INPUT[progressBar(title(⭐Rating), minValue(1), maxValue(10), class('custom-progress-bar'), addLabels(true)):dayRating]
```

### Quick Notes

uuh

carbonara métisos
(1 dose = 30 ml)
igredientes (2 pessoas):
- [] spagetti (ou fettuccine (recomendado)) (250g)
- [] bacon pancetta ou guaciale (180-200g)
- [] parmesão ou pecorino (80-100g)
- [] ovos (4) (3 gemas + 1 ovo)
- [] 1 dose de whisky bourbon (woodford reserve >>>)
- [] pimenta do reino (pkrl)
- sem óleo.

igredientes (6 pessoas):
- [] spaghetti ou fettuccine (600-700g, por aí)
- [] Bacon Pancetta ou Guanciale (350-400g)
- [] ovos (8) (6 gemas, 2 inteiros)
- [] 3 doses de whisky bourbon (woodford reserve >>>) (+1 pra vc)
- [] parmesão ou pecorino (250-300g)
- [] pimenta do reino (a gosto, bastante até)
- [] sal (POUQUÍSSIMO se possível)
- sem óleo.

modo de preparo:
1. coloca o bacon picado em cubos na panela e acende em fogo médio (deixa o bgl derreter a gordura), além disso já coloca o macarrão pra cozinhar.
2. bate as gemas usando fouet.
3. joga um tanto (quase tudo, guardar um pouco pra finalizar) de parmesão (OU pecorino).
4. uma pitada de pimenta do reino (pitada de mão).
5. mexe de novo a mistura. Esse é o molho. sim, só isso. (não precisa de sal normalmente, já que o bacon já é meio salgado). Tem que ficar uma massa grossa, quase de bolo, se tiver mto líquida antes do macarrão, é pouco queijo.
6. APÓS o bacon fritar, desligue o fogo, ele vai ter soltado bastante gordura, caso desejado, pode pegar um guardanapo pra poder absorver um pouco da gordura (MAS NÃO ABSORVE MUITO, A GORDURA FAZ PARTE DO MOLHO).
7. o secret: pega umas 2 conchas da água do macarrão e separa, pega as doses de whisky, joga aos poucos e vai mexendo, tem q deixar reduzir bem aqui. prova e vê se ficou legal, vai adicionando aos poucos e deixando evaporar até ficar com um tom não licoroso, mas algo mais balnceado. E TIRA A FRIGIDEIRA DO FOGO PRA FAZER ISSO PRA N FLAMBAR. joga um quarto de concha da água que ajuda a emulsificar o molho.
8. pega o macarrão e joga na panela do bacon. FOGO DESLIGADO e já comeća a misturar. O macarrão deve sair da panela +- 1-2 minutos antes do ponto (vamos continuar cozinhando ele).
9. joga a mistura de ovos no macarrão e mistura, isso deve deixar tudo mais firme já que estamos efetivamente cozinhando o ovo no macarrão (de novo, não muito, não queremos ovos mexidos ou cozidos no macarrão). Enquanto vai misturando, vai jogando a água do cozimento na mistura aos poucos até finalizar, o intúito é manter quente, não deixar os ovos cozinharem ou mexerem e ter um molho meio aveludado. ISSO DEVE DURAR NO MÁXIMO 2 MIN.
10. por fim, joga o parmesão (ou pecorino) e pimenta no prato.
11. secret-2: vc pode tbm tostar essa pimenta antes de ralar no prato pra dar mais aroma.

---
<p hidden>placer</p>

`BUTTON[new-thought, highlight, idea]`
```meta-bind-button
id: new-thought
style: primary
class: phone-responsive
label: 🎯 Progress
hidden: true
actions:
  - type: command
    command: "templater-obsidian:06 Templates/Components/New Progress.md"
  - type: sleep 
    ms: 2
  - type: command
    command: templater-obsidian:jump-to-next-cursor-location 
```
```meta-bind-button
id: highlight
style: primary
class: phone-responsive
label: ✨ Highlight
hidden: true
actions:
  - type: command
    command: "templater-obsidian:06 Templates/Components/New Highlight.md"
  - type: sleep 
    ms: 2
  - type: command
    command: templater-obsidian:jump-to-next-cursor-location 
```
```meta-bind-button
id: idea
style: primary
class: phone-responsive
label: 💡 Idea
hidden: true
actions:
  - type: command
    command: "templater-obsidian:06 Templates/Components/New Idea.md"
  - type: sleep 
    ms: 2
  - type: command
    command: templater-obsidian:jump-to-next-cursor-location 
```
---
>[! journal]- &nbsp;This Note From Different Years
>```dataview
TABLE alias
FROM "01 Daily"
WHERE dateformat(date, "MM-dd") = dateformat(this.file.day, "MM-dd") AND file.name != this.file.name
SORT date DESC
>```

### Q&A
---