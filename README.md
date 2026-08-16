# DENNYS BOT - Entregas

Distribuicao protegida para instalacao automatica no Pterodactyl/Jexactyl.

## Egg

Importe `egg-dennys-delivery-bot.json` em um Nest do painel. Na criacao do
servidor, informe o nome do bot, o nome do dono, o numero do dono e o numero
do WhatsApp usado no pareamento.

O codigo de pareamento aparece no console do servidor. O prefixo `¥` permanece
fixo e nao e configuravel pelo Egg.

## Requisitos

- Imagem `ghcr.io/parkervcp/yolks:nodejs_22`
- Acesso do Wings ao GitHub e ao registro `ghcr.io`
- Saida HTTPS liberada para validar o IP autorizado e conectar ao WhatsApp

Software proprietario. Redistribuicao e engenharia reversa nao autorizadas.
