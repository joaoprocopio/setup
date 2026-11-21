# tools

Instala e configura uma máquina Debian em duas contas Linux: a conta admin
(pessoal, no grupo `sudo`) e a conta de trabalho (sem sudo).

## Passo a passo

1. Instale o Debian com LUKS e deixe a senha do root vazia no instalador. Assim
   a primeira conta que você criar entra no grupo `sudo`.
2. Nessa conta: `sudo apt install git`, clone `https://github.com/joaoprocopio/setup.git`,
   rode `./src/install.sh` e escolha o perfil `pessoal`. Ela instala o que é da
   máquina inteira e configura a própria home.
3. Crie a conta de trabalho, sem sudo: `sudo adduser --shell /usr/bin/zsh <usuário>`.
4. Saia da sessão e entre na conta de trabalho pela tela de login, não por
   `su`: o docker rootless e as configurações do GNOME precisam da sessão
   própria dela. Lá, clone `https://github.com/joaoprocopio/setup.git`, rode
   `./src/install.sh` e escolha o perfil `trabalho`. Ela configura só a própria
   home, em cima do que a conta admin instalou, e nunca chama sudo.
5. Depois de mudar um passo que tem parte de sistema, rode `./src/install.sh`
   na conta admin primeiro. A conta de trabalho mostra `espera o admin` em
   `./src/install.sh --list` até isso acontecer.

Na primeira vez, cada conta escolhe o perfil e a identidade do git. Elas ficam
em `~/.config/tools/profile`, fora do repositório.
