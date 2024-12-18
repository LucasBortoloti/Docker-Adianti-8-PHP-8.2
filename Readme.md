# Docker + PHP + Nginx + Adianti

Antes de criar o container usando a extensão é preciso ter uma pasta .devcontainer e dentro um arquivo devcontainer.json especificando determinadas configurações, além obviamente do Dockerfile.

# Comandos para criar e utilizar um container Docker com volumes utilizando a extensão Dev Container:

Ctrl + Shift + P

Dev Containers: Rebuild and Reopen in Container

# Dicas relacionadas com o volume e a extensão Dev Container 

Com a extensão Dev Container nem é necessário fazer os comandos do docker, para criar a imagem e o container, ela já faz isso para você. Porém o dockerfile, e o devcontainer devem estar bem configurados para funcionar corretamente.

É possível e bom ainda deixar a extensão do docker instalada, pois ela é muito boa para gerenciar os containers que estão em execução, porém a partir do momento que você cria o container com a extensão Dev Container a extensão do docker some, ai para ter acesso novamente é necessário reabrir o vs code, ou mesmo clicar em File + New Window, assim irá abrir uma outra janela do VS Code, onde vai aparecer a extensão do Docker e será possível utiliza-lá.

Eu tive um problema com a extensão do docker, onde qualquer alteração que eu fizesse em algum arquivo do container a partir da extensão, ele salvava como root mesmo eu especificando o usuario no dockerfile, acredito que deve haver alguma solução para isso, mas eu não consegui arrumar esse problema. Já com a Dev Container funcionou perfeitamente.

# Para especificar outro diretório diferente do template, seria necessário fazer algumas alterações:

No devcontainer.json: mudar o workspaceMount e o workspaceFolder

No Dockerfile: na parte do nginx.conf mudar o root para diretório desejado.

### d:) :v:
