# Etap 1: Tworzenie własnego obrazu bazowego
# Używamy pustego obrazu bazowego (scratch), na którym budujemy Alpine Linux
FROM scratch AS base
# Dodajemy minimalny system plików Alpine Linux do obrazu
ADD alpine-minirootfs-3.21.3-x86_64.tar /

# Etap 2: Instalacja wymaganych pakietów i budowanie aplikacji
# Tworzymy nową warstwę obrazu na podstawie wcześniej utworzonego `base`
FROM base AS builder
# Instalujemy Node.js i pnpm (menedżer pakietów dla Node.js)
RUN apk add --no-cache nodejs pnpm

# Ustawiamy katalog roboczy w kontenerze na `/app`
WORKDIR /app

# Kopiujemy pliki konfiguracyjne projektu do katalogu roboczego
COPY package.json tsconfig.json .env ./

# Instalujemy zależności projektu
RUN pnpm install 

# Kopiujemy kod źródłowy aplikacji do katalogu roboczego
COPY src ./src 

# Budujemy aplikację (kompilacja TypeScript do JavaScript)
RUN pnpm build

# Etap 3: Uruchomienie aplikacji za pomocą serwera Nginx 
# Używamy obrazu `nginx:alpine` jako podstawy  
FROM nginx:alpine AS nginx-server

# Instalujemy Node.js i pnpm również w tym etapie, aby móc uruchomić aplikację  
RUN apk add --no-cache nodejs pnpm

# Ustawiamy katalog roboczy na `/app`  
WORKDIR /app

# Kopiujemy zbudowaną aplikację z warstwy `builder` do finalnego obrazu  
COPY --from=builder /app ./

# Kopiujemy konfigurację Nginx, która będzie używana do obsługi aplikacji  
COPY nginx.conf /etc/nginx/nginx.conf

# Tworzymy zmienną ARG dla wersji aplikacji, domyślnie ustawioną na "1.0.0"
ARG VERSION="1.0.0"
# Przekazujemy wartość ARG do zmiennej środowiskowej ENV, aby była dostępna w kontenerze
ENV APP_VERSION=$VERSION

# Dokumentujemy port 80, na którym będzie działać aplikacja
EXPOSE 80

# Konfigurujemy mechanizm sprawdzania kondycji kontenera (healthcheck)  
# Co 10 sekund sprawdzamy, czy serwer Nginx odpowiada  
HEALTHCHECK --interval=10s --timeout=1s --retries=3 CMD curl -f http://localhost:80/ || exit 1

# Uruchamiamy aplikację:  
# 1. `pnpm start` - uruchamia aplikację Node.js  
# 2. `nginx -g 'daemon off;'` - uruchamia serwer Nginx w trybie pierwszoplanowym  
CMD ["sh", "-c", "pnpm start & nginx -g 'daemon off;'"]

