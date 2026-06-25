# Git Learning Log

## Mijn huidige begrip

Git is een checkpoint-systeem voor mijn projectbestanden.

Een commit is een veilig opgeslagen punt. Als ik daarna iets fout doe in VS Code, kan ik met Git zien wat er veranderd is en eventueel terug naar de laatste goede commit.

## Belangrijkste zones

- Working directory: mijn huidige bestanden in VS Code.
- Staging area: bestanden die klaarstaan voor een commit.
- Commit: een opgeslagen checkpoint op mijn laptop.
- Remote/GitHub: online kopie van mijn commits.

## Belangrijkste commando’s nu

- git status: laat zien wat gewijzigd, nieuw of staged is.
- git diff: laat zien wat ik heb veranderd sinds de laatste commit.
- q: uit de git diff viewer gaan.
- git add <bestand>: zet bestand klaar voor commit.
- git commit -m "...": maakt een checkpoint.
- git restore <bestand>: gooit niet-gecommitte wijzigingen weg en zet bestand terug naar de laatste commit.

## Wat ik vandaag heb geleerd

Voor een risicovolle refactor moet mijn working tree eerst clean zijn. Als ik iets fout doe vóórdat ik commit, kan git restore mij terugbrengen naar de laatste goede versie.