# https://ja.osdn.net/projects/xtbook/wiki/Install-Linux 
# 以上のWebサイトを参考にして記述しました。

FROM ubuntu:20.04

LABEL maintainer="reishoku <reishoku@mail.reishoku.net>" \ 
      version="20210801.original" \ 
      description="XTBookで使用できる辞書を作成する"

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i -e 's/archive.ubuntu/ja.archive.ubuntu/g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y build-essential mecab libmecab-dev mecab-ipadic kakasi libkakasi2-dev libxml2-dev liblzma-dev g++ make wget curl nkf
RUN cd /usr/src && wget https://ftp.jaist.ac.jp/pub/GNU/libiconv/libiconv-1.14.tar.gz -O - | tar zxvf - && cd libiconv-1.14 && sed -i -e "s/^_GL_WARN_ON_USE/\/\/_GL_WARN_ON_USE/g" srclib/stdio.in.h && ./configure && make && make install && echo "/usr/local/lib" | tee --append /etc/ld.so.conf && ldconfig
RUN cd && wget https://github.com/yvt/xtbook/releases/download/v0.2.6/MkXTBWikiplexus-R3.tar.gz -O - | tar zxvf - && cd MkXTBWikiplexus/build.unix && sed -i -e '252 s/gets(buf)/scanf("%s",buf)!=EOF/' ../MkImageComplex/main.cpp && make

ENV PATH /root/MkXTBWikiplexus/build.unix:$PATH
RUN cd && wget "https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2" && echo "Extracting..." && bunzip2 -d jawiki-latest-pages-articles.xml.bz2
RUN cd && mkdir -p BUILD.jawiki && cd BUILD.jawiki && MkXTBWikiplexus-bin -o jawiki-latest.xtbdict < ../jawiki-latest-pages-articles.xml && cd jawiki-latest.xtbdict && YomiGenesis-bin < BaseNames.csv > Yomi.txt && MkXTBIndexDB-bin -o Search Yomi.txt
RUN cd ~/BUILD.jawiki/jawiki-latest.xtbdict && MkRax-bin -o Articles.db.rax < Articles.db
RUN { \
        echo 'opcache.memory_consumption=128'; \
	echo '<?xml version="1.0" encoding="UTF-8"?>'; \
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'; \
	echo '<plist version="1.0">'; \
	echo '<dict>'; \
	echo '	<key>XTBDictionaryIdentifier</key>'; \
	echo '	<string>com.nexhawks.XTBook.Wikipedia.ja</string>'; \
	echo '	<key>XTBDictionaryScheme</key>'; \
	echo '	<string>jawiki</string>'; \
	echo '	<key>XTBDictionaryTypeIdentifier</key>'; \
	echo '	<string>com.nexhawks.XTBook.Wikiplexus</string>'; \
	echo '	<key>XTBWikiplexusArticlesFile</key>'; \
	echo '	<string>Articles</string>'; \
	echo '	<key>XTBWikiplexusTemplatesFile</key>'; \
	echo '	<string>Templates</string>'; \
	echo '	<key>XTBWikiplexusSiteInfoFile</key>'; \
	echo '	<string>SiteInfo.plist</string>'; \
	echo '	<key>XTBWikiplexusSearchFile</key>'; \
	echo '	<string>Search</string>'; \
	echo '	<key>XTBWikiplexusSchemeForImages</key>'; \
	echo '	<string>jawikiimg</string>'; \
	echo '	<key>XTBDictionaryDisplayName</key>'; \
	echo '	<string>ウィキペディア 日本語版</string>'; \
	echo '</dict>'; \
	echo '</plist>'; \
} > ./Info.plist

# RUN tar zcf jawiki-latest.xtbdict.tar.gz jawiki-latest.xtbdict/

RUN echo "Done!"
