# Instala os pacotes necess�rios
# install.packages(c("mFilter", "BCDating", "tidyverse", "ggfortify", "zoo"))


library(mFilter)
library(BCDating)
library(ggplot2)
library(ggfortify)
library(gridExtra)
library(zoo)


# Carrega dados do arquivo
PIBSPDESMENSAL <- read.table("PIBSPDESMENSAL.txt", header = 1)
pibspdes.ts <- ts(PIBSPDESMENSAL[,1], start = c(2002, 1), freq = 12)

# Calcula os ciclos de neg�cios
dc <- BBQ(
    log(pibspdes.ts)*100,
    name="Dating Business Cycles of LOG PIBSP DESSAZONALIZADO")
# Os picos e os vales dos ciclos podem ser acessados atrav�s de 'dc@peaks' e 
# 'dc@troughs', respectivamente
a <- c(as.Date(dc@y)[1], as.Date(dc@y)[dc@peaks])
b <- as.Date(dc@y)[dc@troughs]
# O in�cio e fim de cada ciclo � salvo num dataframe
business.cycle <- data.frame(Topo=a, Vale=b)

# Calcula os componentes do filtro HP
pibsphp <- hpfilter(pibspdes.ts, freq = 14400, type = c("lambda"), drift = FALSE)
# A fun��o retorna uma 'lista'
# Os componentes podem ser acessados individualmente atrav�s de pibsphp$trend
# (tend�ncia) e pibsphp$cycle (ciclo)
a <- cbind(pibsphp$x, pibsphp$trend, pibsphp$cycle)
pibspdes.ts <- data.frame(as.matrix(a), as.Date(as.yearmon(time(a))))
colnames(pibspdes.ts) <- c("PIB", "Trend", "Cycle", "Date")


# Define algumas vari�rveis para as fun��es de plotagem
plot.limits <- as.Date(c("2010-12-01", "2019-04-01"))
plot.date_breaks <- "1 month"
plot.date_minor_breaks <- "1 month"


# Para gerar os gr�ficos utilizo o pacote 'ggplot2'
# Cada gr�fico � criado separadamente
g1 <- ggplot(pibspdes.ts, aes(x = Date)) +
    geom_line(aes(y = PIB), color = "black") +
    geom_line(aes(y = Trend), color = "red") + 
    ylim(95, 115) +
    # Adiciona-se um 'geom' do tipo linha com a s�rie de tend�ncia calculada pelo filtro HP
    geom_rect(                  # Para marcar os ciclos, utiliza-se o 'geom' 
        data = business.cycle,  # rect com o dataframe 'business.cycle'
        inherit.aes = FALSE,
        aes(xmin = Topo, xmax = Vale, ymin = -Inf, ymax = Inf),
        alpha = 0.2) +
    theme_bw() +   # Esta linha aplica o tema preto e branco no gr�fico
    scale_x_date(  # Para personalizar a escala utiliza-se esta fun��o
        date_labels = "%Y-%m",  # Especifica o formato das marcas de escala: Ano-M�s
        date_breaks = plot.date_breaks,  # Especifica o intervalo entre as marcas
        date_minor_breaks = plot.date_minor_breaks,   # Especifica o intervalo da grade secund�ria
        limits = plot.limits) +
    ylab("PIB SP dessazonalizado") +
    ggtitle("PIB SP e Ciclo de Negocios") +
    theme(
        axis.title.x = element_blank(),  # Remove a escala x desse gr�fico,
        axis.text.x = element_blank(),   # pois ser� a mesma para o gr�fico abaixo
        axis.ticks.x = element_blank(),
        plot.title = element_text(lineheight = .8, face = "bold"))

g2 <- ggplot(pibspdes.ts, aes(x = Date, y = Cycle)) +
    geom_col() +
    geom_rect(
        data = business.cycle,
        inherit.aes=FALSE,
        aes(xmin = Topo, xmax = Vale, ymin = -Inf, ymax = Inf),
        alpha = 0.2) +
    theme_bw() +
    scale_x_date(
        date_labels = "%Y-%m",
        date_breaks = plot.date_breaks,
        date_minor_breaks = plot.date_minor_breaks,
        limits = plot.limits) +
    ylab("Filtro HP - Ciclo") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.25))

# Para gerar uma figura com os dois gr�ficos utilizo a fun��o 'grid.arrange'
# do pacote 'gridExtra'
g <- grid.arrange(g1, g2, ncol = 1, heights = c(1.5, 1))

# Salva a figura
ggsave(file = "plot.png", plot = g, width = 16, height = 9, dpi = 300)


# REFER�NCIAS:
# https://stackoverflow.com/questions/26741703/adding-multiple-shadows-rectangles-to-ggplot2-graph#26757536
# https://stackoverflow.com/questions/7056836/how-to-fix-the-aspect-ratio-in-ggplot
# https://r-graphics.org/chapter-bar-graph
