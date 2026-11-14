/* Kurmaca oyuncu adları için ad/soyad havuzları.
   Yalnız yaygın adlar ve soyadlar kullanılır; ünlü futbolculara özgü ayırt edici soyadlar havuza konmaz.
   Üretilen ad-soyad YASAKLI listesindeki bir gerçek kişiyle aynıysa yeniden çekilir. */

const S = s => s.trim().split(/\s*,\s*/).filter(Boolean);

export const DIL = {
  tr: {
    ad: S(`Ahmet, Mehmet, Mustafa, Ali, Hüseyin, Hasan, İbrahim, İsmail, Osman, Yusuf, Murat, Ömer, Ramazan, Halil, Süleyman, Abdullah, Mahmut, Recep, Salih, Fatih,
      Kemal, Kadir, Emre, Burak, Serkan, Hakan, Onur, Volkan, Uğur, Tolga, Tuncay, Sinan, Erkan, Gökhan, Cem, Can, Deniz, Barış, Umut, Kaan,
      Berk, Efe, Arda, Emir, Eren, Yiğit, Batuhan, Doğukan, Furkan, Enes, Taha, Yasin, Alperen, Oğuzhan, Kerem, Mert, Ozan, Alp, Berkay, Selim,
      Tarık, Erdem, Koray, Levent, Okan, Orkun, Sefa, Taylan, Utku, Yunus, Zafer, Anıl, Bora, Cenk, Çağlar, Dorukhan, Egemen, Ferhat, Görkem, Ilgaz,
      Kubilay, Melih, Nazım, Rıdvan, Sercan, Tayfun, Ufuk, Yavuz, Zeki, Atakan, Baran, Çınar, Ege, Kutay, Metehan, Poyraz, Talha, Toprak, Yağız, Bartu`),
    soyad: S(`Yılmaz, Kaya, Demir, Şahin, Çelik, Yıldız, Yıldırım, Öztürk, Aydın, Özdemir, Arslan, Doğan, Kılıç, Aslan, Çetin, Kara, Koç, Kurt, Özkan, Şimşek,
      Polat, Özcan, Korkmaz, Çakır, Erdoğan, Yavuz, Can, Acar, Şen, Aktaş, Güler, Yalçın, Güneş, Bozkurt, Bulut, Keskin, Ünal, Turan, Gül, Özer,
      Tekin, Kaplan, Işık, Sarı, Avcı, Kahraman, Ateş, Karakaya, Uçar, Taş, Tunç, Altun, Karaca, Akın, Kocabaş, Kalkan, Ekinci, Sezer, Erol, Tuna,
      Akbulut, Başaran, Coşkun, Duman, Ergin, Gündoğdu, Kaplankaya, Karabulut, Kocaman, Kurtuluş, Oral, Önal, Pehlivan, Saygın, Soylu, Taşdemir, Uysal, Vural, Yüce, Zengin,
      Akgül, Aksoy, Altıntaş, Bayram, Bilgin, Cengiz, Çiftçi, Demirci, Dinç, Durmaz, Eren, Erkan, Gök, Gürbüz, Kara, Karataş, Kılınç, Metin, Okur, Sönmez,
      Tatlı, Toprak, Uslu, Yazıcı, Yiğit, Akyüz, Bal, Çoban, Dağ, Ekin, Fidan, Gürsoy, İnce, Kandemir, Oğuz, Sevim, Tok, Ulus, Yaman, Yurt`) },
  en: {
    ad: S(`Jack, Harry, George, Oliver, Charlie, Thomas, James, William, Joshua, Daniel, Samuel, Joseph, Lewis, Ryan, Jamie, Connor, Callum, Kieran, Liam, Nathan,
      Tom, Ben, Luke, Adam, Alex, Ethan, Jacob, Max, Mason, Dylan, Kyle, Jordan, Aaron, Matthew, Michael, Owen, Reece, Sam, Tyler, Will,
      Alfie, Archie, Freddie, Harvey, Henry, Isaac, Jake, Louis, Noah, Oscar, Rhys, Toby, Zach, Elliot, Finley, Ollie, Rory, Scott, Sean, Theo`),
    soyad: S(`Smith, Jones, Taylor, Brown, Williams, Wilson, Johnson, Davies, Robinson, Wright, Thompson, Evans, Walker, White, Roberts, Green, Hall, Wood, Jackson, Clarke,
      Turner, Hill, Cooper, Ward, Morris, Moore, Clark, Lee, King, Baker, Harrison, Morgan, Allen, James, Scott, Phillips, Watson, Davis, Parker, Price,
      Bennett, Young, Griffiths, Mitchell, Kelly, Cook, Carter, Richardson, Bailey, Collins, Bell, Shaw, Murphy, Miller, Cox, Richards, Khan, Marshall, Anderson, Simpson,
      Ellis, Adams, Wilkinson, Foster, Chapman, Mason, Gray, Hunt, Palmer, Holmes, Mills, Barnes, Knight, Lloyd, Butler, Russell, Barker, Fisher, Stevens, Jenkins,
      Dixon, Fletcher, Hart, Pearson, Gibson, Andrews, Lawrence, Hughes, Webb, Rose`) },
  es: {
    ad: S(`Alejandro, Pablo, Daniel, Javier, David, Adrián, Álvaro, Sergio, Carlos, Diego, Mario, Jorge, Manuel, Iván, Rubén, Víctor, Raúl, Hugo, Marcos, Iker,
      Alberto, Andrés, Antonio, Borja, Cristian, Eduardo, Enrique, Fernando, Gonzalo, Guillermo, Ignacio, Jaime, Jesús, Joaquín, Juan, Luis, Miguel, Nicolás, Óscar, Rafael,
      Ramón, Roberto, Rodrigo, Santiago, Unai, Mikel, Asier, Aitor, Ander, Jon, Xabier, Pedro, Martín, Lucas, Bruno, Samuel, Aleix, Pol, Marc, Arnau`),
    soyad: S(`García, Fernández, González, Rodríguez, López, Martínez, Sánchez, Pérez, Gómez, Martín, Jiménez, Ruiz, Hernández, Díaz, Moreno, Muñoz, Álvarez, Romero, Alonso, Gutiérrez,
      Navarro, Torres, Domínguez, Vázquez, Ramos, Gil, Ramírez, Serrano, Blanco, Molina, Morales, Suárez, Ortega, Delgado, Castro, Ortiz, Rubio, Marín, Sanz, Núñez,
      Iglesias, Medina, Garrido, Cortés, Castillo, Santos, Lozano, Guerrero, Cano, Prieto, Méndez, Cruz, Calvo, Gallego, Herrera, Márquez, León, Peña, Flores, Cabrera,
      Campos, Vega, Fuentes, Carrasco, Diez, Caballero, Reyes, Nieto, Aguilar, Pascual, Santana, Herrero, Montero, Lorenzo, Hidalgo, Giménez, Ibáñez, Ferrer, Durán, Santiago`) },
  it: {
    ad: S(`Francesco, Alessandro, Andrea, Lorenzo, Matteo, Gabriele, Leonardo, Riccardo, Davide, Tommaso, Giuseppe, Antonio, Federico, Marco, Luca, Giovanni, Mattia, Simone, Pietro, Filippo,
      Edoardo, Christian, Nicolò, Stefano, Daniele, Emanuele, Michele, Paolo, Roberto, Salvatore, Vincenzo, Alberto, Fabio, Giacomo, Jacopo, Manuel, Massimo, Raffaele, Samuele, Valerio,
      Diego, Elia, Enrico, Fabrizio, Gianluca, Luigi, Mario, Nicola, Sergio, Thomas, Cristian, Domenico, Gianmarco, Ivan, Mirko, Ottavio, Raul, Tiziano, Umberto, Vittorio`),
    soyad: S(`Rossi, Russo, Ferrari, Esposito, Bianchi, Romano, Colombo, Ricci, Marino, Greco, Bruno, Gallo, Conti, De Luca, Mancini, Costa, Giordano, Rizzo, Lombardi, Moretti,
      Barbieri, Fontana, Santoro, Mariani, Rinaldi, Caruso, Ferrara, Galli, Martini, Leone, Longo, Gentile, Martinelli, Vitale, Lombardo, Serra, Coppola, De Santis, D'Angelo, Marchetti,
      Parisi, Villa, Conte, Ferraro, Ferri, Fabbri, Bianco, Marini, Grasso, Valentini, Messina, Sala, De Angelis, Gatti, Pellegrini, Palumbo, Sanna, Farina, Rizzi, Monti,
      Cattaneo, Morelli, Amato, Silvestri, Mazza, Testa, Grassi, Pellegrino, Carbone, Giuliani, Benedetti, Barone, Rossetti, Caputo, Montanari, Guerra, Palmieri, Bernardi, Martino, Fiore`) },
  de: {
    ad: S(`Lukas, Leon, Finn, Jonas, Paul, Luca, Felix, Elias, Tim, Niklas, Jan, Julian, Max, Moritz, Noah, Ben, David, Tom, Philipp, Fabian,
      Florian, Tobias, Sebastian, Simon, Dominik, Marcel, Kevin, Dennis, Patrick, Daniel, Christian, Michael, Matthias, Jonathan, Benedikt, Maximilian, Nico, Lennart, Erik, Jannik,
      Marvin, Robin, Pascal, Sven, Stefan, Timo, Kai, Lars, Malte, Henrik, Johannes, Konstantin, Leonard, Luis, Mats, Ole, Till, Valentin, Vincent, Yannick`),
    soyad: S(`Müller, Schmidt, Schneider, Fischer, Weber, Meyer, Wagner, Becker, Schulz, Hoffmann, Schäfer, Koch, Bauer, Richter, Klein, Wolf, Schröder, Neumann, Schwarz, Zimmermann,
      Braun, Krüger, Hofmann, Hartmann, Lange, Schmitt, Werner, Schmitz, Krause, Meier, Lehmann, Schmid, Schulze, Maier, Köhler, Herrmann, König, Walter, Mayer, Huber,
      Kaiser, Fuchs, Peters, Lang, Scholz, Möller, Weiß, Jung, Hahn, Schubert, Vogel, Friedrich, Keller, Günther, Frank, Berger, Winkler, Roth, Beck, Lorenz,
      Baumann, Franke, Albrecht, Schuster, Simon, Ludwig, Böhm, Winter, Kraus, Martin, Schumacher, Krämer, Vogt, Stein, Jäger, Otto, Sommer, Groß, Seidel, Heinrich`) },
  fr: {
    ad: S(`Lucas, Hugo, Louis, Nathan, Gabriel, Jules, Arthur, Raphaël, Théo, Tom, Enzo, Maxime, Antoine, Alexandre, Baptiste, Clément, Thomas, Quentin, Romain, Valentin,
      Mathis, Paul, Victor, Adrien, Benjamin, Florian, Guillaume, Julien, Kevin, Nicolas, Pierre, Sébastien, Vincent, Yanis, Axel, Bastien, Corentin, Dylan, Erwan, Evan,
      Gaëtan, Jérémy, Jordan, Killian, Léo, Loïc, Malo, Matteo, Noé, Rayan, Sacha, Samuel, Simon, Thibault, Timothée, Tristan, Yohan, Aurélien, Cédric, Damien`),
    soyad: S(`Martin, Bernard, Thomas, Petit, Robert, Richard, Durand, Dubois, Moreau, Laurent, Simon, Michel, Lefebvre, Leroy, Roux, David, Bertrand, Morel, Fournier, Girard,
      Bonnet, Dupont, Lambert, Fontaine, Rousseau, Vincent, Muller, Lefèvre, Faure, André, Mercier, Blanc, Guérin, Boyer, Garnier, Chevalier, François, Legrand, Gauthier, Garcia,
      Perrin, Robin, Clément, Morin, Nicolas, Henry, Roussel, Mathieu, Gautier, Masson, Marchand, Duval, Denis, Dumont, Marie, Lemaire, Noël, Meyer, Dufour, Meunier,
      Brun, Blanchard, Giraud, Joly, Rivière, Lucas, Brunet, Gaillard, Barbier, Arnaud, Martinez, Gérard, Roche, Renard, Schmitt, Roy, Leroux, Colin, Vidal, Caron`) },
  pt: {
    ad: S(`João, Pedro, Tiago, Diogo, Rafael, Gonçalo, Rodrigo, Miguel, Bruno, Ricardo, Nuno, André, Luís, Francisco, Vítor, Hugo, Fábio, Rúben, Sérgio, Daniel,
      Lucas, Gabriel, Matheus, Gustavo, Felipe, Leonardo, Vinícius, Thiago, Caio, Renan, Igor, Wesley, Everton, Douglas, Danilo, Marcelo, Fernando, Rafinha, Willian, Paulo`),
    soyad: S(`Silva, Santos, Ferreira, Pereira, Oliveira, Costa, Rodrigues, Martins, Jesus, Sousa, Fernandes, Gonçalves, Gomes, Lopes, Marques, Alves, Almeida, Ribeiro, Pinto, Carvalho,
      Teixeira, Moreira, Correia, Mendes, Nunes, Soares, Vieira, Monteiro, Cardoso, Rocha, Neves, Coelho, Cruz, Cunha, Pires, Ramos, Reis, Simões, Antunes, Matos,
      Barbosa, Araújo, Lima, Nascimento, Moura, Freitas, Batista, Castro, Andrade, Dias`) },
  nl: {
    ad: S(`Daan, Sem, Lucas, Levi, Finn, Milan, Bram, Luuk, Thijs, Jesse, Ruben, Stijn, Lars, Tim, Niels, Joost, Koen, Bas, Wouter, Sander,
      Jeroen, Pieter, Maarten, Jasper, Rick, Tom, Mees, Teun, Jens, Gijs, Wout, Arne, Senne, Lander, Robbe, Jelle, Kobe, Seppe, Dries, Toon`),
    soyad: S(`de Jong, Jansen, de Vries, van den Berg, van Dijk, Bakker, Visser, Smit, Meijer, de Boer, Mulder, de Groot, Bos, Vos, Peters, Hendriks, van Leeuwen, Dekker, Brouwer, de Wit,
      Dijkstra, Smits, de Graaf, van der Meer, Kok, Jacobs, de Haan, Vermeulen, van den Heuvel, van der Veen, Peeters, Maes, Claes, Goossens, Wouters, Mertens, Willems, Janssens, Lemmens, Hermans`) },
  ar: {
    ad: S(`Mohamed, Ahmed, Youssef, Karim, Amine, Mehdi, Hamza, Bilal, Ayoub, Ismail, Anas, Yassine, Adam, Rayan, Nabil, Samir, Walid, Sofiane, Riyad, Ilyes,
      Zakaria, Hakim, Omar, Abdel, Faycal, Hicham, Khalid, Mounir, Nassim, Rachid`),
    soyad: S(`Benali, El Amrani, Haddad, Bennani, Chakir, Idrissi, Belkacem, Mansouri, Ziani, Hamdi, Bouzid, Saidi, Brahimi, Cherif, Amrani, Toumi, Kaddour, Boukhari, Lahlou, Rahmani,
      Tazi, Ouali, Mezian, Djellouli, Benaissa, Hadj, Bensaid, Larbi, Khelifi, Zerrouki`) },
  afr: {
    ad: S(`Moussa, Ibrahima, Mamadou, Cheikh, Abdou, Ousmane, Seydou, Lamine, Boubacar, Aliou, Souleymane, Modou, Idrissa, Pape, Babacar, Yaya, Kalidou, Serge, Wilfried, Franck, Aristide, Didier, Jean, Junior`),
    soyad: S(`Diallo, Ndiaye, Diop, Sow, Fall, Sy, Ba, Gueye, Faye, Cissé, Traoré, Koné, Coulibaly, Touré, Camara, Keita, Sangaré, Diarra, Konaté, Bamba, Kouassi, Yao, Kouamé, Konan, Mbarga, Nkoulou, Ekambi, Fofana`) },
  bafr: {
    ad: S(`Emmanuel, Samuel, Daniel, Kelechi, Chidi, Tunde, Ifeanyi, Kwame, Kofi, Yaw, Kwabena, Joseph, Victor, Paul, Christian, Eric, Michael, Benjamin, Felix, Isaac`),
    soyad: S(`Okafor, Okonkwo, Eze, Nwosu, Adeyemi, Okoro, Mensah, Owusu, Boateng, Asante, Ofori, Addo, Adebayo, Olawale, Nwachukwu, Agyeman, Appiah, Danso, Obi, Bello`) },
  slav: {
    ad: S(`Luka, Marko, Ivan, Nikola, Petar, Stefan, Filip, Matej, Josip, Ante, Mateo, Domagoj, Dejan, Milan, Nemanja, Lazar, Aleksandar, Dušan, Vuk, Bojan, Edin, Amir, Haris, Emir, Armin, Kenan`),
    soyad: S(`Horvat, Kovačević, Babić, Marić, Jurić, Knežević, Vuković, Petrović, Jovanović, Nikolić, Marković, Đorđević, Stojanović, Ilić, Pavlović, Milošević, Popović, Lukić, Kostić, Hodžić, Begić, Mehmedović, Hasanović, Delić, Kovač, Šarić`) },
  bslav: {
    ad: S(`Jakub, Kamil, Piotr, Mateusz, Krzysztof, Tomasz, Michał, Bartosz, Jan, Ondřej, Tomáš, Lukáš, Adam, Dawid, Paweł, Marek, Wojciech, Patrik, Václav, Jiří, Filip, Szymon`),
    soyad: S(`Nowak, Kowalski, Wiśniewski, Wójcik, Kamiński, Zieliński, Szymański, Woźniak, Dąbrowski, Kozłowski, Jankowski, Mazur, Krawczyk, Dvořák, Svoboda, Novotný, Černý, Procházka, Kučera, Veselý, Horák, Němec`) },
  nord: {
    ad: S(`Mikkel, Rasmus, Mads, Jonas, Emil, Oliver, Magnus, Andreas, Kasper, Christian, Erik, Lars, Anders, Johan, Viktor, Gustav, Axel, Oscar, Filip, Simon,
      Henrik, Sander, Martin, Kristian, Jesper, Nils, Tobias, Isak, Elias, Sebastian`),
    soyad: S(`Jensen, Nielsen, Hansen, Pedersen, Andersen, Christensen, Larsen, Sørensen, Rasmussen, Jørgensen, Johansson, Karlsson, Nilsson, Eriksson, Larsson, Olsson, Persson, Svensson, Gustafsson, Pettersson,
      Berg, Haugen, Johansen, Olsen, Kristiansen, Lund, Lindberg, Holm, Dahl, Strand`) },
  lat: {
    ad: S(`Juan, Santiago, Matías, Nicolás, Agustín, Facundo, Lautaro, Thiago, Franco, Joaquín, Bruno, Federico, Gonzalo, Maximiliano, Ezequiel, Leandro, Gastón, Rodrigo, Sebastián, Emiliano,
      Luis, Jhon, Andrés, Camilo, Cristian, Jhon Jairo, Wilmar, Yerson, Darwin, Brayan`),
    soyad: S(`González, Rodríguez, Fernández, López, Martínez, Pérez, Gómez, Díaz, Sosa, Romero, Benítez, Acosta, Medina, Herrera, Aguirre, Pereyra, Giménez, Molina, Silva, Castro,
      Rojas, Vargas, Cardona, Mosquera, Valencia, Zapata, Quintero, Arias, Cabrera, Ríos`) },
  jp: {
    ad: S(`Takumi, Kaito, Ryota, Shota, Yuki, Daiki, Kenta, Haruto, Sota, Riku, Yuto, Hiroki, Kazuki, Naoki, Taichi`),
    soyad: S(`Sato, Suzuki, Takahashi, Tanaka, Watanabe, Ito, Yamamoto, Nakamura, Kobayashi, Kato, Yoshida, Yamada, Sasaki, Matsumoto, Inoue`) },
  kr: {
    ad: S(`Min-jun, Ji-ho, Seung-woo, Hyun-woo, Jun-young, Dong-hyun, Sung-min, Tae-yang, Woo-jin, Jae-won, Ji-hoon, Sang-ho, Young-jae`),
    soyad: S(`Kim, Lee, Park, Choi, Jung, Kang, Cho, Yoon, Jang, Lim, Han, Oh, Seo`) },
  gur: {
    ad: S(`Giorgi, Levan, Davit, Luka, Nika, Irakli, Saba, Zurab, Otar, Lasha, Beka, Guram`),
    soyad: S(`Beridze, Kapanadze, Gelashvili, Maisuradze, Lomidze, Tsiklauri, Chikhladze, Gogia, Mchedlidze, Kiteishvili, Abuladze, Kobakhidze`) },
  aze: {
    ad: S(`Elvin, Ramil, Rauf, Emin, Tural, Orkhan, Mahir, Namik, Ruslan, Vugar, Kamran, Elnur`),
    soyad: S(`Mammadov, Aliyev, Huseynov, Hasanov, Guliyev, Ismayilov, Abbasov, Rzayev, Safarov, Nazarov, Jafarov, Karimov`) },
  alb: {
    ad: S(`Arbër, Ardit, Besart, Dren, Ermal, Kristjan, Elseid, Klaus, Amir, Endrit, Valon, Florent`),
    soyad: S(`Hoxha, Krasniqi, Gashi, Berisha, Shala, Kelmendi, Morina, Rexhepi, Bytyqi, Daku, Muçi, Kastrati`) },
};

/* Uyruklar: kod → { ad, bayrak, dil(ler) }. Ad ve soyad havuzu dile göre seçilir. */
export const UYRUK = {
  TR: { ad: 'Türkiye', b: '🇹🇷', dil: ['tr'] }, EN: { ad: 'İngiltere', b: '🏴', dil: ['en'] }, ES: { ad: 'İspanya', b: '🇪🇸', dil: ['es'] },
  IT: { ad: 'İtalya', b: '🇮🇹', dil: ['it'] }, DE: { ad: 'Almanya', b: '🇩🇪', dil: ['de'] }, FR: { ad: 'Fransa', b: '🇫🇷', dil: ['fr'] },
  PT: { ad: 'Portekiz', b: '🇵🇹', dil: ['pt'] }, BR: { ad: 'Brezilya', b: '🇧🇷', dil: ['pt'] }, NL: { ad: 'Hollanda', b: '🇳🇱', dil: ['nl'] },
  BE: { ad: 'Belçika', b: '🇧🇪', dil: ['nl', 'fr'] }, AT: { ad: 'Avusturya', b: '🇦🇹', dil: ['de'] }, CH: { ad: 'İsviçre', b: '🇨🇭', dil: ['de', 'fr'] },
  AR: { ad: 'Arjantin', b: '🇦🇷', dil: ['lat'] }, UY: { ad: 'Uruguay', b: '🇺🇾', dil: ['lat'] }, CO: { ad: 'Kolombiya', b: '🇨🇴', dil: ['lat'] },
  SN: { ad: 'Senegal', b: '🇸🇳', dil: ['afr'] }, CI: { ad: 'Fildişi Sahili', b: '🇨🇮', dil: ['afr'] }, NG: { ad: 'Nijerya', b: '🇳🇬', dil: ['bafr'] },
  GH: { ad: 'Gana', b: '🇬🇭', dil: ['bafr'] }, CM: { ad: 'Kamerun', b: '🇨🇲', dil: ['afr'] }, ML: { ad: 'Mali', b: '🇲🇱', dil: ['afr'] },
  MA: { ad: 'Fas', b: '🇲🇦', dil: ['ar'] }, DZ: { ad: 'Cezayir', b: '🇩🇿', dil: ['ar'] }, TN: { ad: 'Tunus', b: '🇹🇳', dil: ['ar'] },
  HR: { ad: 'Hırvatistan', b: '🇭🇷', dil: ['slav'] }, RS: { ad: 'Sırbistan', b: '🇷🇸', dil: ['slav'] }, BA: { ad: 'Bosna-Hersek', b: '🇧🇦', dil: ['slav'] },
  PL: { ad: 'Polonya', b: '🇵🇱', dil: ['bslav'] }, CZ: { ad: 'Çekya', b: '🇨🇿', dil: ['bslav'] }, DK: { ad: 'Danimarka', b: '🇩🇰', dil: ['nord'] },
  SE: { ad: 'İsveç', b: '🇸🇪', dil: ['nord'] }, NO: { ad: 'Norveç', b: '🇳🇴', dil: ['nord'] }, JP: { ad: 'Japonya', b: '🇯🇵', dil: ['jp'] },
  KR: { ad: 'Güney Kore', b: '🇰🇷', dil: ['kr'] }, GE: { ad: 'Gürcistan', b: '🇬🇪', dil: ['gur'] }, AZ: { ad: 'Azerbaycan', b: '🇦🇿', dil: ['aze'] },
  AL: { ad: 'Arnavutluk', b: '🇦🇱', dil: ['alb'] }, US: { ad: 'ABD', b: '🇺🇸', dil: ['en'] },
};

/* Lig başına yerli oranı ve yabancı uyruk ağırlıkları (kabaca gerçekçi dağılım). */
export const LIG_UYRUK = {
  tr: { yerli: 'TR', oran: 0.58, yabanci: { BR: 6, PT: 4, NL: 3, BE: 2, SN: 4, CI: 3, NG: 3, GH: 2, CM: 2, MA: 3, DZ: 2, HR: 3, RS: 3, BA: 3, PL: 2, CZ: 2, DK: 2, SE: 2, NO: 1, AR: 3, UY: 2, CO: 3, GE: 2, AZ: 1, AL: 2, KR: 1, JP: 1, DE: 2, FR: 2 } },
  en: { yerli: 'EN', oran: 0.38, yabanci: { FR: 6, ES: 4, PT: 5, BR: 5, NL: 4, BE: 4, DE: 3, DK: 3, SE: 2, NO: 3, AR: 3, UY: 2, CO: 2, SN: 3, CI: 3, NG: 3, GH: 3, CM: 2, MA: 2, HR: 2, RS: 2, PL: 2, CZ: 1, JP: 2, KR: 2, US: 3, IT: 2, CH: 2, AT: 1, ML: 2 } },
  es: { yerli: 'ES', oran: 0.6, yabanci: { FR: 5, PT: 4, BR: 5, AR: 6, UY: 4, CO: 3, NL: 2, BE: 2, DE: 1, IT: 1, MA: 4, SN: 2, CI: 2, NG: 2, GH: 2, CM: 2, HR: 2, RS: 2, JP: 2, KR: 1, US: 1, DK: 1, SE: 1, NO: 1, GE: 1 } },
  it: { yerli: 'IT', oran: 0.42, yabanci: { FR: 5, ES: 3, PT: 3, BR: 5, AR: 6, UY: 3, CO: 3, NL: 4, BE: 4, DE: 3, DK: 3, SE: 2, NO: 2, PL: 4, CZ: 2, HR: 4, RS: 4, BA: 2, AL: 3, GE: 2, SN: 3, CI: 3, NG: 3, GH: 3, CM: 2, MA: 2, CH: 3, AT: 2, US: 2, ML: 2 } },
  de: { yerli: 'DE', oran: 0.5, yabanci: { AT: 6, CH: 5, FR: 5, NL: 4, BE: 3, DK: 4, SE: 3, NO: 3, PL: 3, CZ: 3, HR: 3, RS: 2, BA: 2, PT: 2, ES: 2, BR: 3, AR: 1, SN: 2, CI: 3, NG: 2, GH: 3, CM: 2, MA: 2, JP: 4, KR: 3, US: 3, GE: 2, AL: 1, ML: 2 } },
  fr: { yerli: 'FR', oran: 0.55, yabanci: { BE: 5, CH: 3, PT: 4, ES: 2, BR: 4, AR: 3, CO: 2, NL: 2, DE: 2, DK: 2, SN: 6, CI: 6, CM: 5, ML: 5, MA: 5, DZ: 5, TN: 3, NG: 2, GH: 3, HR: 2, RS: 2, GE: 2, JP: 2, KR: 2, US: 2, NO: 1, SE: 1, PL: 1 } },
};

/* Gerçek ünlü futbolcuların ad-soyadı: bu eşleşmeler hiçbir zaman üretilmez (benzerliği önlemek için). */
export const YASAKLI = new Set(S(`
  Mehmet Topal, Emre Belözoğlu, Hakan Şükür, Arda Turan, Burak Yılmaz, Cenk Tosun, Volkan Demirel, Selçuk İnan, Hamit Altıntop, Nihat Kahveci,
  Rüştü Reçber, Tuncay Şanlı, Hasan Şaş, Alpay Özalan, Bülent Korkmaz, Ümit Davala, Okan Buruk, Sergen Yalçın, Tanju Çolak, Rıdvan Dilmen,
  Oğuz Çetin, Feyyaz Uçar, Metin Tekin, Mustafa Denizli, Fatih Terim, Şenol Güneş, Ersun Yanal, Gökhan Gönül, Caner Erkin, Ozan Tufan,
  Mert Günok, Uğurcan Çakır, Altay Bayındır, Kaan Ayhan, Merih Demiral, Ferdi Kadıoğlu, Zeki Çelik, Orkun Kökçü, Salih Özcan, İrfan Can Kahveci,
  Kerem Aktürkoğlu, Barış Alper Yılmaz, Yunus Akgün, Arda Güler, Kenan Yıldız, Semih Kılıçsoy, Enes Ünal, Abdülkerim Bardakcı, Ahmetcan Kaplan, Mert Müldür,
  Eren Elmalı, Ismail Yüksek, İsmail Yüksek, Bertuğ Yıldırım, Can Uzun, Oğuz Aydın, Yusuf Sarı, Emre Mor, Halil Dervişoğlu, Kerem Demirbay,
  Harry Kane, Jack Grealish, Harry Maguire, Jordan Henderson, Jordan Pickford, Kyle Walker, Luke Shaw, Mason Mount, Declan Rice, Marcus Rashford,
  Phil Foden, Bukayo Saka, Jude Bellingham, Cole Palmer, Raheem Sterling, John Stones, Kieran Trippier, Ben White, Aaron Ramsdale, Jack Wilshere,
  Steven Gerrard, Frank Lampard, Wayne Rooney, David Beckham, Paul Scholes, Gary Neville, Rio Ferdinand, John Terry, Ashley Cole, Michael Owen,
  Sergio Ramos, Carlos Puyol, Xavi Hernández, Andrés Iniesta, David Villa, Fernando Torres, David Silva, Iker Casillas, Pedro Rodríguez, Álvaro Morata,
  Dani Carvajal, Rodrigo Hernández, Pablo Gavi, Marcos Llorente, Mikel Oyarzabal, Unai Simón, Dani Olmo, Ferran Torres, Nico Williams, Pedri González,
  Daniel Carvajal, Jordi Alba, Sergio Busquets, Gerard Piqué, Raúl González, Fernando Hierro, Joan Capdevila, Jesús Navas, Santi Cazorla, Juan Mata,
  Gianluigi Buffon, Andrea Pirlo, Francesco Totti, Alessandro Del Piero, Paolo Maldini, Fabio Cannavaro, Giorgio Chiellini, Leonardo Bonucci, Marco Verratti, Lorenzo Insigne,
  Federico Chiesa, Nicolò Barella, Ciro Immobile, Gianluigi Donnarumma, Alessandro Bastoni, Lorenzo Pellegrini, Federico Dimarco, Sandro Tonali, Davide Frattesi, Giacomo Raspadori,
  Andrea Belotti, Daniele De Rossi, Gennaro Gattuso, Christian Vieri, Filippo Inzaghi, Roberto Baggio, Marco Materazzi, Alessandro Nesta, Gianluca Zambrotta, Luca Toni,
  Thomas Müller, Manuel Neuer, Toni Kroos, Mats Hummels, Philipp Lahm, Bastian Schweinsteiger, Mesut Özil, İlkay Gündoğan, Joshua Kimmich, Leon Goretzka,
  Kai Havertz, Leroy Sané, Serge Gnabry, Marc-André ter Stegen, Antonio Rüdiger, Niklas Süle, Timo Werner, Julian Brandt, Florian Wirtz, Jamal Musiala,
  Miroslav Klose, Michael Ballack, Oliver Kahn, Lukas Podolski, Per Mertesacker, Jérôme Boateng, Mario Götze, Marco Reus, Sami Khedira, Benedikt Höwedes,
  Kylian Mbappé, Antoine Griezmann, Olivier Giroud, Hugo Lloris, Paul Pogba, N'Golo Kanté, Raphaël Varane, Karim Benzema, Ousmane Dembélé, Kingsley Coman,
  Theo Hernández, Lucas Hernández, Jules Koundé, Dayot Upamecano, Aurélien Tchouaméni, Eduardo Camavinga, Adrien Rabiot, Mike Maignan, Thierry Henry, Zinedine Zidane,
  Patrick Vieira, Robert Pirès, Claude Makélélé, Lilian Thuram, Marcel Desailly, Franck Ribéry, Benjamin Pavard, Lucas Digne, Randal Kolo Muani, Marcus Thuram,
  Cristiano Ronaldo, Bruno Fernandes, Bernardo Silva, João Félix, Rúben Dias, João Cancelo, Diogo Jota, Rafael Leão, Pepe Ferreira, Nuno Mendes,
  Vinícius Júnior, Gabriel Jesus, Lucas Paquetá, Richarlison Andrade, Casemiro Silva, Marquinhos Corrêa, Thiago Silva, Dani Alves, Gabriel Martinelli, Raphinha Dias,
  Virgil van Dijk, Frenkie de Jong, Matthijs de Ligt, Memphis Depay, Daley Blind, Denzel Dumfries, Arjen Robben, Robin van Persie, Wesley Sneijder, Kevin De Bruyne,
  Romelu Lukaku, Eden Hazard, Thibaut Courtois, Jan Vertonghen, Toby Alderweireld, Dries Mertens, Youri Tielemans, Leandro Trossard, Jérémy Doku, Axel Witsel,
  Luka Modrić, Ivan Perišić, Mateo Kovačić, Marcelo Brozović, Joško Gvardiol, Ivan Rakitić, Dušan Vlahović, Aleksandar Mitrović, Sergej Milinković, Robert Lewandowski,
  Wojciech Szczęsny, Piotr Zieliński, Christian Eriksen, Kasper Schmeichel, Erling Haaland, Martin Ødegaard, Alexander Isak, Zlatan Ibrahimović, Viktor Gyökeres, Son Heung-min,
  Kim Min-jae, Takefusa Kubo, Kaoru Mitoma, Takumi Minamino, Wataru Endo, Sadio Mané, Kalidou Koulibaly, Édouard Mendy, Mohamed Salah, Achraf Hakimi,
  Riyad Mahrez, Hakim Ziyech, Yassine Bounou, Victor Osimhen, Wilfred Ndidi, Kelechi Iheanacho, Thomas Partey, Mohammed Kudus, André Onana, Sébastien Haller,
  Lionel Messi, Ángel Di María, Sergio Agüero, Lautaro Martínez, Julián Álvarez, Emiliano Martínez, Enzo Fernández, Alexis Mac Allister, Rodrigo De Paul, Paulo Dybala,
  Luis Suárez, Edinson Cavani, Diego Godín, Federico Valverde, Darwin Núñez, Ronald Araújo, James Rodríguez, Radamel Falcao, Luis Díaz, Juan Cuadrado,
  Christian Pulisic, Weston McKennie, Tyler Adams, Giorgi Mamardashvili, Khvicha Kvaratskhelia
`));

/* Listede olmayan uyruklar: ISO kodundan bayrak ve Türkçe ülke adı (İngiltere ülkeleri özel). */
const BK = { EN: ['İngiltere', '🏴󠁧󠁢󠁥󠁮󠁧󠁿'], SC: ['İskoçya', '🏴󠁧󠁢󠁳󠁣󠁴󠁿'], WL: ['Galler', '🏴󠁧󠁢󠁷󠁬󠁳󠁿'], NI: ['Kuzey İrlanda', '🇬🇧'] };
const _onbellek = {};
export function uyrukBilgi(k) {
  if (!k) return { ad: '—', b: '🏳️', dil: ['en'] };
  if (BK[k]) return { ...(UYRUK[k] || { dil: ['en'] }), ad: BK[k][0], b: BK[k][1] };
  if (UYRUK[k]) return UYRUK[k];
  if (_onbellek[k]) return _onbellek[k];
  let ad = k;
  try { ad = new Intl.DisplayNames(['tr'], { type: 'region' }).of(k) || k; } catch (e) { /* eski tarayıcı */ }
  const b = /^[A-Z]{2}$/.test(k) ? String.fromCodePoint(...[...k].map(c => 0x1F1E6 + c.charCodeAt(0) - 65)) : '🏳️';
  return (_onbellek[k] = { ad, b, dil: ['en'] });
}
