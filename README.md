Database Refactoring
====================

Repositório com exemplos práticos de Database Refactorings utilizando PostgreSQL e PL/pgSQL.

### Como funciona?

Utilizando Vagrant iniciamos uma instância PostgreSQL em uma máquina virtual local.

### Instalação

Primeiro instale [Vagrant] e [Virtual Box].

Então execute o que segue para criar uma máquina virtual com PostgreSQL:

	# Clonar repositorio:
    $ git clone https://github.com/fabriziomello/database_refactoring database_refactoring

    # Entre no diretório clonado:
    $ cd database_refactoring

    # Opcionalmente edite o usuário/senha do banco de dados:
    $ $EDITOR Vagrant-setup/bootstrap.sh

### Uso

    # Iniciar a máquina virtual:
    $ vagrant up

    # Parar a máquina virtual:
    $ vagrant halt

### O que faz isso?

Cria uma máquina virtual rodando Ubuntu 12.04 com a última versão do PostgreSQL (*atualmente 9.3*) instalada. Também edita a configuração do PostgreSQL para permitir acesso tcp/ip e cria usuário e banco para ser utilizado na oficina.

Uma vez iniciado o processo será exibido na tela como acessar o banco de dados na máquina virtual. Algo como:

    $ vagrant up
    Bringing machine 'default' up with 'virtualbox' provider...
    [... truncated ...]
    Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)
      Host: localhost
      Port: 15432
      Database: agilebrazil
      Username: agilebrazil
      Password: agilebrazil

    Admin access to postgres user via VM:
      vagrant ssh
      sudo su - postgres

    psql access to app database user via VM:
      vagrant ssh
      sudo su - postgres
      PGUSER=agilebrazil PGPASSWORD=agilebrazil psql -h localhost agilebrazil

    Env variable for application development:
      DATABASE_URL=postgresql://agilebrazil:agilebrazil@localhost:15432/agilebrazil

    Local command to access the database via psql:
      PGUSER=agilebrazil PGPASSWORD=agilebrazil psql -h localhost -p 15432 agilebrazil

### Porque utilizar shell script para provisionar a máquina virtual?

Alternativas: [Chef](http://www.getchef.com/chef/), [Puppet](http://puppetlabs.com/), [Ansible](http://www.ansibleworks.com/), ou [Salt](http://www.saltstack.com/)?

Principalmente porque é simples e qualquer um com conhecimento básico de shell script poder modificar o `bootstrap.sh` de acordo com suas necessidades.

## Licença
(The MIT License)

Copyright (C) 2014 Fabrízio de Royes Mello

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Virtual Box]: https://www.virtualbox.org/
[Vagrant]: http://www.vagrantup.com/
