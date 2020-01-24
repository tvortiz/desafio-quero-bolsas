

load 'organizar_palestras.rb'

require 'test/unit'





class TestPalestra < Test::Unit::TestCase


    # Teste de Unidade da classe Palestra
    def test_Unit_Palestra

        p1 = Palestra.new ("Writing Fast Tests Against Enterprise Rails 60min")

        assert_equal 60, p1.duracao
        assert_equal "Writing Fast Tests Against Enterprise Rails", p1.nome


        p2 = Palestra.new ("Rails for Python Developers lightning")

        assert_equal 5, p2.duracao
        assert_equal "Rails for Python Developers", p2.nome

    end


    # Teste de Unidade da Classe Trilha
    def test_Unit_Trilha

        trilha = Trilha.new

        trilha.sessao_Manha.push Palestra.new "aaaaaa 10min"
        trilha.sessao_Manha.push Palestra.new "bbbbbb 20min"
        trilha.sessao_Manha.push Palestra.new "cccccc 30min"

        trilha.sessao_Tarde.push Palestra.new "dddddd 10min"
        trilha.sessao_Tarde.push Palestra.new "eeeeee 20min"
        trilha.sessao_Tarde.push Palestra.new "ffffff 30min"
        trilha.sessao_Tarde.push Palestra.new "gggggg 30min"


        assert_equal 3, trilha.sessao_Manha.length
        assert_equal 4, trilha.sessao_Tarde.length

    end


    # Teste de Unidade de entrada de dados
    def test_Unit_input

        palestras = import_JSON_File "in.json"

        assert_equal 19, palestras.length

        assert_equal 60, palestras[0].duracao
        assert_equal "Writing Fast Tests Against Enterprise Rails", palestras[0].nome

        assert_equal 45, palestras[1].duracao
        assert_equal "Overdoing it in Python", palestras[1].nome

        assert_equal 30, palestras[2].duracao
        assert_equal "Lua for the Masses", palestras[2].nome

        # ... 

        assert_equal 5, palestras[5].duracao
        assert_equal "Rails for Python Developers", palestras[5].nome

        # ...

        assert_equal 30, palestras[18].duracao
        assert_equal "User Interface CSS in Rails Apps", palestras[18].nome

    end








    # Teste de Integração entre as classes Palestras e Sessão
    def test_Integration_Palestra_Sessao

        trilha = Trilha.new
        p1 = Palestra.new "aaaaaa 30min"
        p2 = Palestra.new "bbbbbb 30min"
        p3 = Palestra.new "cccccc 30min"
        p4 = Palestra.new "dddddd 60min"
        p5 = Palestra.new "eeeeee 60min"
        p6 = Palestra.new "ffffff 60min"
        trilha.sessao_Manha.append p1, p2, p3
        trilha.sessao_Tarde.append p4, p5, p6
        

        # adiciona 3 palestras de manhã, as 9:30, 10h e 10:30, todas com 30 min de duração
        p1.horario = hour_to_min_passed(9, 00)
        p2.horario = hour_to_min_passed(9, 30)
        p3.horario = hour_to_min_passed(10, 00)

        # adiciona 3 palestras de tarde, as 13, 14h e 15h
        p4.horario = hour_to_min_passed(13, 00)
        p5.horario = hour_to_min_passed(14, 00)
        p6.horario = hour_to_min_passed(15, 00)

        # verifica se não há sobreposições nas sessões (neste caso, não há)
        assert_true valida_Trilha trilha

        # verifica se não há janelas entre as palestras (neste caso, não há)
        assert_true valida_Trilha trilha


        # coloca a 2a palestra no horário da 1a
        p2.horario = hour_to_min_passed(9, 00)
        # deve dar errado, isto não é permitido
        assert_false valida_Trilha trilha


        # coloca a 2a palestra acabando depois da 3a
        p2.horario = hour_to_min_passed(9, 40)
        # deve dar erro, isto não é permitido
        assert_false valida_Trilha trilha


        # aumenta o começo da 3a palestra, mas causa uma janela entre as palestras
        p3.horario = hour_to_min_passed(10, 20)
        # deve dar erro, não pode haver janelas
        assert_false valida_Trilha trilha

    end




    # Teste funcional chamando a função que realiza a montagem da programação
    def test_Integration_Conferencia

        palestras = import_JSON_File "in.json"

        trilhas = monta_programacao palestras

        trilhas.each do |trilha|
            assert_true valida_Trilha trilha
        end


        export_JSON_File trilhas, "out.json"

    end


end






# ####################################################
# ### FUNÇÕES AUXILIARES PARA VALIDAÇÕES DOS DADOS ###
# ####################################################


# Valida se a trilha está de acordo com as regras, analisando as regras da manhã e tarde.
# Params:
# - trilha: a trilha a ser avaliada
# Output: true caso esteja de acordo
def valida_Trilha (trilha)

    # para validar a trilha, serão verificadas as sessões da manhã e tarde (separadas pois possuem regras diferentes)

    return false unless valida_Sessao_Manha trilha.sessao_Manha
    return false unless valida_Sessao_Tarde trilha.sessao_Tarde

    return true
end


# Valida se a parte da manhã está de acordo com as regras
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Sessao_Manha (trilhas)

    # A sessão da manhã possuí 4 regras, são elas:
    # 1 - não pode haver palestras no mesmo horário ou que acabem depois do inicio de outra
    # 2 - não pode haver janelas entre as palestras
    # 3 - começar as 9h da manhã
    # 4 - acabar antes das 12h

    # para validar a sessão, todas estas regras são validadas abaixo (em ordem de 1-4)

    return false unless valida_Sobreposissao_Sessao trilhas
    return false unless valida_Espacos_em_Branco_Sessao trilhas
    return false unless valida_Inicio_Sessao trilhas, 9
    return false unless valida_Final_Sessao_Manha trilhas
    return true

end


# Valida se a parte da tarde está de acordo com as regras
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Sessao_Tarde (trilhas)

    # As sessão da tarde possuí 4 regras, são elas:
    # 1 - não pode haver palestras no mesmo horário ou que acabem depois do inicio de outra
    # 2 - não pode haver janelas entre as palestras
    # 3 - começar as 13h
    # 4 - terminar entre 16h e 17h

    # para validar a sessão, todas estas regras são validadas abaixo (em ordem de 1-4)
    return false unless valida_Sobreposissao_Sessao trilhas
    return false unless valida_Espacos_em_Branco_Sessao trilhas
    return false unless valida_Inicio_Sessao trilhas, 13
    return false unless valida_Final_Sessao_Tarde trilhas
    return true
end






# Procura se existem sessões sobrepostas, isto é, no mesmo horário
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Sobreposissao_Sessao (trilhas)

    horarios = []
    trilhas.each { |t|  horarios.append t.horario}

    # caso remova os 'repetidos' e a quantidade seja diferente, é porque há palestras no mesmo horário
    if horarios.uniq.length != trilhas.length
        return false
    end

    #ordena as sessoes da trilha em ordem de horario
    trilhas.sort! {|x,y| x.horario <=> y.horario}

    # verifica se o horario de inicio mais a duracao, irá ultrapassar a próxima palestra
    trilhas.each_with_index do |pal,i|
        next_pal = trilhas[i+1]
        if next_pal && pal.horario + pal.duracao > next_pal.horario
            return false
        end
    end

    return true

end







# Procura se existem espaços em branco entre as palestras (ignorando possivelmente o almoço e happy hour)
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Espacos_em_Branco_Sessao (trilhas)
  
    # ordena as sessoes da trilha em ordem de horario
    trilhas.sort! {|x,y| x.horario <=> y.horario}

    # verifica se o horario de inicio mais a duracao será o mesmo da próxima palestra
    trilhas.each_with_index do |pal,i|

        next_pal = trilhas[i+1]

        # ignora o almoço
        next if next_pal == nil or next_pal.nome == "Lunch" or next_pal.nome == "Networking Event"

        if pal.horario + pal.duracao != next_pal.horario
            return false
        end
    end

    return true

end



# Procura se as sessões possuí uma palestra no horario de abertura
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Inicio_Sessao (trilhas, hora)
    trilhas.each { |t| return true if t.horario == hour_to_min_passed(hora, 0) }
    return false
end


# Verifica se alguma palestra passa o horário permitido  (para a parte da tarde)
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Final_Sessao_Manha (trilhas)
    
    trilhas.each do |t| 
        next if t.nome == "Lunch"
        return false if t.horario + t.duracao > hour_to_min_passed(12, 0) 
    end

    return true
end


# Verifica se alguma palestra passa o horário permitido (para a parte da tarde)
# Params:
# - trilhas: vetor de objetos do tipo Trilhas
# Output: true caso esteja de acordo
def valida_Final_Sessao_Tarde (trilhas)

    # verifica se alguma passa o horário permitido (17h)
    trilhas.each do |t| 
        next if t.nome == "Networking Event"
        return false if t.horario + t.duracao > hour_to_min_passed(17, 0) 
    end


    # verifica se a ultima sessão acaba antes das 16h
    last = trilhas.sort! {|x,y| x.horario <=> y.horario}.last
    return false if (last.horario + last.duracao) < hour_to_min_passed(16, 0)

    return true
end

