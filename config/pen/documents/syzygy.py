from collections import defaultdict

    
def get_sub_words_dict(words):
    sub_words_dict = defaultdict(lambda:set())
    for word in words:
        #For each sub section. ie. one letter, two letter ... n letter sub words
        sub_words = set()
        for i in range(len(word)):
            j = 0
            sub_section_len = i
            while (j+sub_section_len) < len(word):
                sub_word = word[j:(j+1)+sub_section_len]
                #put the word into the sub words dict
                sub_words_dict[sub_word].add(word)
                sub_words.add(sub_word)
                j += 1
    return sub_words_dict

def get_sub_words(word):
    #For each sub section. ie. one letter, two letter ... n letter sub words
    sub_words = []
    for i in range(len(word)):
        j = 0
        sub_section_len = i
        while (j+sub_section_len) < len(word):
            sub_word = word[j:(j+1)+sub_section_len]
            sub_words.append(sub_word)
            j += 1
    return sub_words

def get_syzygies(word,sub_words_dict):
    def sort_by_sub_word_len(syzygy):        
        return syzygy[1]
    syzygies = {}
    sub_words = get_sub_words(word)
    for s in sub_words:
        sub_word_len = len(s)
        #This is in the order of small -> large sub words
        for word in sub_words_dict[s]:
            #This is so we prefer larger match than a small match
            syzygies[word] = (word,sub_word_len,s)
    #Sort by descending sub words (better syzygies)
    syzygies = list(syzygies.values())
    syzygies.sort(key=sort_by_sub_word_len,reverse=True)
    return syzygies

def get_common_syzygies(word1,word2,sub_words_dict):
    def sort_by_sub_word_len(syzygy):        
        return syzygy[1]
    def intersection(lst1, lst2):
        return list(set(lst1) & set(lst2))
    syzygies = {}    
    word1_sub_words = get_sub_words(word1)
    word2_sub_words = get_sub_words(word2)

    sub_words_both = intersection(word1_sub_words,word2_sub_words)

    for s in sub_words_both:
        sub_word_len = len(s)
        #This is in the order of small -> large sub words
        for word in sub_words_dict[s]:
            #This is so we prefer larger match than a small match
            syzygies[word] = (word,sub_word_len,s)
    #Sort by descending sub words (better syzygies)
    syzygies = list(syzygies.values())
    syzygies.sort(key=sort_by_sub_word_len,reverse=True)
    return syzygies


#Build dictionary 
special_words = ["apple","plane","lecun","snap","lane","lecture"]       
with open("english_words.txt","r") as file:
    words = []
    lines = file.readlines()
    for l in lines:
        words.append(l.replace("\n",""))
sub_words_dict = get_sub_words_dict(words)

#Inference
word = "shane"
syzygies = get_syzygies(word,sub_words_dict)

#Get top 5 syzygies
print(syzygies[:5])

#Get common syzygies between two words
word1 = "bowl"
word2 = "rowl"
common_syzygies = get_common_syzygies(word1,word2,sub_words_dict)
print(common_syzygies[:5])

#TODO 
#common syzygies between many words

#TODO
#generate syzygy tree

#TODO 
#calculate scores for syzygy game





