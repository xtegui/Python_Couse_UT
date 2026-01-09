#!/usr/bin/env bash
set -euo pipefail

W=25        # kN
mu=0.75

# Puntos como en tu plot (0,10,...,80)
angles=(0 10 20 30 40 50 60 70 80)

data="pull_force_mu${mu}.dat"
png="pull_force_mu${mu}.png"

: > "$data"

# Generar tabla: angle(deg)  force(kN)
for a in "${angles[@]}"; do
  awk -v W="$W" -v mu="$mu" -v deg="$a" 'BEGIN{
    pi=atan2(0,-1);
    th=deg*pi/180;
    P=mu*W/(cos(th)+mu*sin(th));
    printf "%d %.6f\n", deg, P
  }' >> "$data"
done

# Calcular óptimo continuo (theta=atan2(mu,1))
theta_opt=$(awk -v mu="$mu" 'BEGIN{pi=atan2(0,-1); printf "%.6f", atan2(mu,1)*180/pi}')
P_opt=$(awk -v W="$W" -v mu="$mu" 'BEGIN{
  pi=atan2(0,-1);
  th=atan2(mu,1);
  P=mu*W/(cos(th)+mu*sin(th));
  printf "%.6f", P
}')

gnuplot <<GNUPLOT
set terminal pngcairo size 1100,700
set output "${png}"

set title "Given W = ${W} kN and mu = ${mu}, what's the optimum {/Symbol q}?"

set xlabel "pulling angle (degrees)"
set ylabel "required pulling force (kN)"
set key left top

set grid

# Línea vertical en el óptimo teórico
set arrow 1 from ${theta_opt}, graph 0 to ${theta_opt}, graph 1 nohead

# Punto cuadrado en el óptimo teórico
set style line 2 lc rgb "black" pt 5 ps 1.4

plot "${data}" using 1:2 with linespoints lc rgb "red" pt 7 ps 1.2 title "mu = ${mu}", \
     "-" using 1:2 with points ls 2 title sprintf("opt \\{/Symbol q}=%.2f° (P=%.2f kN)", ${theta_opt}, ${P_opt})
${theta_opt} ${P_opt}
e

GNUPLOT

echo "Generated: ${png}"
echo "Data file: ${data}"
echo "Optimum theta: ${theta_opt} deg"
echo "P(theta_opt): ${P_opt} kN"
