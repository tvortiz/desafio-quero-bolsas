require 'json'


class Palestra
  
  attr_reader :nome, :duracao
  attr_accessor :horario
  
  def initialize (str)
    @nome = extract_nome str
    @duracao = extract_duracao str
    @horario = 0
  end
  
  def extract_nome str
  	if str.include? "lightning"
  		return str.sub ' lightning', ''
	else	
	    return str.sub /\s\d+min/, ''
	end
  end  
  
  def extract_duracao str
  	if str.include? "lightning"
  		return 5
  	else
    	return str.scan(/\d+min/).join.delete('min').to_i
    end
  end
  
  private :extract_nome, :extract_duracao
  
end





class Trilha
	attr_accessor :sessao_Manha, :sessao_Tarde
	def initialize
		@sessao_Manha = []
		@sessao_Tarde = []
	end
end









# monta_programacao

# Esta é a principal função do programa! Ela que monta a programação de acordo com as palestras passadas.
# Ela não utiliza Simplex ou heurísticas de pesquisa operacional, ela utiliza um algoritmo guloso onde as palestras são encaixadas das maiores pras menores, iniciando pelas manhãs e em seguida pela tarde.
# Ao final, são inseridos o almoço e o horário do happy hour no final da ultima palestra do dia.
# Params:
# - palestras: vetor com as palestras a serem montadas no dia
# Output: vetor com objetos do tipo Trilhas
def monta_programacao (palestras)

	# ordena as palestras por duração (do maior pro menor)
	palestras.sort! {|x,y| y.duracao <=> x.duracao}

	total_horas = 0

    palestras.each { |p| total_horas += p.duracao }

    # calcula a qtd minima de sessoes possiveis
    horas_max_dia = 7 * 60.0
    qtd_min_sessao = (total_horas / (horas_max_dia)).ceil

    # guarda as trilhas, comeca com o minimo possivel
    trilhas = []
    qtd_min_sessao.times { trilhas.append Trilha.new }

    
    

    # inicia preenchendo as sessões da parte da manhã
	trilhas.each do |trilha|

		manha = trilha.sessao_Manha

		# se estiver vazio, insere a primeira palestra
		if manha.empty?
			pal = palestras.shift
			encaixa_pal manha, pal	
		end

		# varre todas as palestras procurando candidatos
		for i in 0...palestras.length

			pal = palestras[i]

			# como remove elemento no meio de um for, precisa validar se não eh nulo
			next if pal == nil

			# verifica se a palestra não ultrapassa o horario permitido, caso dê, adiciona à manhã
			if manha.last.horario + manha.last.duracao + pal.duracao <= hour_to_min_passed(12, 0)

				#adiciona à manhã da trilha em questão
				encaixa_pal manha, pal

				# remove da lista de palestras sem horario ainda
				palestras.delete pal

				# como removeu o elemento, volta com o mesmo i
				redo

			end
	    	 
    	end
    end

    # adiciona o almoço a trilha da manha
    trilhas.each do |trilha|
    	lunch = Palestra.new "Lunch 60min"
    	lunch.horario = hour_to_min_passed(12, 0)
		trilha.sessao_Manha.append lunch
	end





	# preenche a parte da tarde
	trilhas.each do |trilha|

		tarde = trilha.sessao_Tarde

		# se estiver vazio, insere a primeira palestra
		if tarde.empty?
			pal = palestras.shift
			encaixa_pal tarde, pal, 13
		end

		# varre todas as palestras procurando candidatos
		for i in 0...palestras.length

			pal = palestras[i]

			# como remove elemento no meio de um for, precisa validar se não eh nulo
			next if pal == nil

			# verifica se a palestra não ultrapassa o horario permitido, caso dê, adiciona à manhã
			if tarde.last.horario + tarde.last.duracao + pal.duracao <= hour_to_min_passed(17, 0)

				#adiciona à manhã da trilha em questão
				encaixa_pal tarde, pal, 13

				# remove da lista de palestras sem horario ainda
				palestras.delete pal

				# como removeu o elemento, volta com o mesmo i
				redo

			end
	    	 
    	end
    end



	# procura a ultima palestra da tarde para colocar o happy hour
	ultima_pal = hour_to_min_passed(13, 0)

    trilhas.each do |trilha|
    	last = trilha.sessao_Tarde.last
    	if last.horario + last.duracao > ultima_pal
    		ultima_pal = last.horario + last.duracao
    	end
	end

	# adiciona o happy hour
	happy_hour = Palestra.new "Networking Event 60min"
	happy_hour.horario = ultima_pal
	trilhas.each { |trilha| trilha.sessao_Tarde.append happy_hour }



    return trilhas

end








# Encaixa palestra no final da trilha, marcando o horário de inicio
# Params:
# - trilha: trilha a qual a palestra será adicionada
# - pal: a palestra a ser adicionada
# - hor: hora de inicio da sessao (default = 9h)
# Output: -
def encaixa_pal (trilha, pal, hor=9)

	if trilha.empty?
		pal.horario = hour_to_min_passed(hor, 0)
	else
		pal.horario = trilha.last.horario + trilha.last.duracao
	end

	trilha.append pal

end


# Converte horas e minutos em minutos decorridos desde a 00h
# Params:
# - hour: horas
# - min - minutos
# Output: minutos decorridos
def hour_to_min_passed (hour, min)
	hour * 60 + min
end


# Converte o tempo em minutos para hora:min:AMPM
# Params:
# - min: minutos desde a 00h
# Output: hora convertida. exemplo: 09:30AM
def min_passed_to_hour (min)
	am_pm = min > 720 ? 'AM' : 'PM'
	h = (min / 60).floor
	m = min - (h * 60)
	return format('%02d', h) + ':' + format('%02d', m) + am_pm
end














# Importa um arquivo JSON com entradas de palestra e preenche um vetor de Palestra
# Params:
# - path: caminho do arquivo
# Output: vetor de objetos do tipo Palestra
def import_JSON_File (path)

	file = File.open path
	data = JSON.load file
	file.close

	palestras = []

	data['data'].each { |nome| palestras.append Palestra.new nome }

	return palestras

end







# Exporta um vetor de trilhas para um arquivo JSON
# Params:
# - trilhas: trilhas contendo as palestras
# - out: caminho do arquivo que será salvo
# Output: vetor de objetos do tipo Palestra
def export_JSON_File (trilhas, out)

	a = []

	# percorre todas as trilhas
	for i in 0...trilhas.length

		trilha = trilhas[i]

		h = {}
		h['title'] = 'Track ' + (i+1).to_s

		# combina as palestras da manhã e tarde
		tmp =        trilha.sessao_Manha.map { |e| min_passed_to_hour(e.horario) + ' ' + e.nome + (e.nome != 'Lunch' ? ' ' + e.duracao.to_s + 'min' : '') }
		tmp += trilha.sessao_Tarde.map { |e| min_passed_to_hour(e.horario) + ' ' + e.nome + (e.nome != 'Networking Event' ? ' ' + e.duracao.to_s + 'min' : '') }

		h['data'] = tmp

		
		a.append h

	end

	tempHash = {'data': a}
	

	File.open(out, "w") do |f|
        f.write(tempHash.to_json)
    end
end
