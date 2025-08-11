# Create Players
player1 = Player.create!(name: 'Player 1')
player2 = Player.create!(name: 'Player 2')
player3 = Player.create!(name: 'Player 3')
player4 = Player.create!(name: 'Player 4')

question_pool = QuestionPool.create!(title: 'Capitals', description: 'Questions about capitals')

questions = [
  { question: 'What is the capital of France?', answer: 'Paris' },
  { question: 'What is the capital of Spain?', answer: 'Madrid' },
  { question: 'What is the capital of Italy?', answer: 'Rome' },
  { question: 'What is the capital of Germany?', answer: 'Berlin' },
  { question: 'What is the capital of Portugal?', answer: 'Lisbon' },
  { question: 'What is the capital of Poland?', answer: 'Warsaw' },
  { question: 'What is the capital of Ukraine?', answer: 'Kyiv' },
  { question: 'What is the capital of Russia?', answer: 'Moscow' },
  { question: 'What is the capital of Turkey?', answer: 'Ankara' },
  { question: 'What is the capital of Greece?', answer: 'Athens' }
]

questions.each do |q|
  Question.create!(text: q[:question], correct_answer: q[:answer], difficulty_level: 1, question_pool: question_pool)
end