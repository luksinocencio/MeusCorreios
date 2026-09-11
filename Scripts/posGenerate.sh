set -euo pipefail

OPEN="${1:-yes}"

# ÚLTIMO PASSO - Abre o projeto após finalizar o comando
if [ "$OPEN" != "no" ]; then
        printf "\nOpening project...\n"
	    open MeusCorreios.xcodeproj
else
    printf '\nMeusCorreios project is closed, please open the project manually\n'
fi

exit 0
