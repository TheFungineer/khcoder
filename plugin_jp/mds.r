d <- t(d)

library(vegan)                                    # MDS�μ¹�
c <- metaMDS( dist(d, method="binary"), k=2 )

plot(c$points, bty="l", pch=20, col="gray60")     # �ɥåȤ�����

library(maptools)                                 # ��٥뤬�Ťʤ�ʤ��褦��
pointLabel(                                       # Ĵ�����Ƥ�������
  x = c$points[,1],
  y = c$points[,2],
  labels = rownames(c$points),
)
