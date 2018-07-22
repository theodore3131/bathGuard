import tensorflow as tf
import numpy as np
print("读取数据")

with open("nopeoplewater.txt" , 'r') as f:
    lines = f.readlines()
datas_np = []
data = []
dic = []
for i,line in enumerate(lines):
    if i%4000== 0 and i!=0 :
        #data = np.array(data[:][:])
        #data = data.reshape((1,-1))
        #print(data.shape)
        dic.append(data)
        dic.append(0)
        datas_np.append(dic)
        data = []
        dic = []
    line = line[:-1]
    line = float(line)
    data.append(line)

datas_np = np.array(datas_np[:][:])
with open("people.txt" , 'r') as f:
    lines = f.readlines()
datas_pe = []
data = []
dic = []
for i,line in enumerate(lines):
    if i%4000== 0 and i!=0 :
        #data = np.array(data[:][:])
        #data = data.reshape((1,-1))
        dic.append(data)
        dic.append(1)
        datas_pe.append(dic)
        data = []
        dic = []
    line = line[:-1]
    line = float(line)
    data.append(line)
datas_pe = np.array(datas_pe[:][:])
# print(datas_pe)

datas_all = np.append(datas_pe,datas_np, axis=0)

np.random.shuffle(datas_all)

test = datas_all[191:]
train = datas_all[:191]
test = datas_all[191:]
train_x =[]
train_y =[]
test_x = []
test_y = []

for i in range(191):
    train_x.append(train[i][0])
    train_y.append([train[i][1]])
for i in range(191,len(datas_all)):
    test_x.append(datas_all[i][0])
    test_y.append([datas_all[i][1]])




train_x = np.array(train_x)*100
train_x = train_x.astype(np.float32)

test_x = np.array(test_x)*100
test_x = test_x.astype(np.float32)
train_y = np.array(train_y)
train_y = train_y.astype(np.float32)
test_y = np.array(test_y)
test_y = test_y.astype(np.float32)

#print(train_y)

print("数据读取完毕")


n_input_layer =4000

n_layer_1 =2000
n_layer_2 = 1000
n_layer_3 = 500
n_layer_4 = 20

n_output_layer = 1

W1 = tf.get_variable("W1", [n_input_layer,n_layer_1], initializer = tf.contrib.layers.xavier_initializer(seed = 1))
b1 = tf.get_variable("b1", [1,n_layer_1], initializer = tf.zeros_initializer())
W2 = tf.get_variable("W2", [n_layer_1,n_layer_2], initializer = tf.contrib.layers.xavier_initializer(seed = 1))
b2 = tf.get_variable("b2", [1,n_layer_2], initializer = tf.zeros_initializer())
W3 = tf.get_variable("W3", [n_layer_2,n_layer_3], initializer = tf.contrib.layers.xavier_initializer(seed = 1))
b3 = tf.get_variable("b3", [1,n_layer_3], initializer = tf.zeros_initializer())
W4 = tf.get_variable("W4", [n_layer_3,n_layer_4], initializer = tf.contrib.layers.xavier_initializer(seed = 1))
b4 = tf.get_variable("b4", [1,n_layer_4], initializer = tf.zeros_initializer())
W5 = tf.get_variable("W5", [n_layer_4,n_output_layer], initializer = tf.contrib.layers.xavier_initializer(seed = 1))
b5 = tf.get_variable("b5", [1,n_output_layer], initializer = tf.zeros_initializer())

# layer_1_w_b = {'w':tf.Variable(tf.random_normal([n_input_layer,n_layer_1])),'b':tf.Variable(tf.random_normal([n_layer_1]))}
# layer_2_w_b = {'w':tf.Variable(tf.random_normal([n_layer_1,n_layer_2])),'b':tf.Variable(tf.random_normal([n_layer_2]))}
# layer_3_w_b = {'w':tf.Variable(tf.random_normal([n_layer_2,n_layer_3])),'b':tf.Variable(tf.random_normal([n_layer_3]))}
# layer_4_w_b = {'w': tf.Variable(tf.random_normal([n_layer_3, n_layer_4])),
#                    'b': tf.Variable(tf.random_normal([n_layer_4]))}
# layer_output_w_b = {'w':tf.Variable(tf.random_normal([n_layer_4,n_output_layer])),'b':tf.Variable(tf.random_normal([n_output_layer ]))}

def neural_network(data):

    layer_1 = tf.add(tf.matmul(data,W1),b1)
    layer_1 = tf.nn.relu(layer_1)
    layer_2 = tf.add(tf.matmul(layer_1,W2),b2)
    layer_2 = tf.nn.relu(layer_2)
    layer_3 = tf.add(tf.matmul(layer_2, W3), b3)
    layer_3 = tf.nn.relu(layer_3)
    layer_4 = tf.add(tf.matmul(layer_3, W4), b4)
    layer_4 = tf.nn.relu(layer_4)
    layer_output = tf.add(tf.matmul(layer_4 , W5) , b5)
    layer_output = tf.nn.sigmoid(layer_output)
    #print(layer_output)

    return layer_output


X = tf.placeholder('float' , [None , 4000])
Y = tf.placeholder('float')

saver = tf.train.Saver()

def train_neural_network(X , Y):
    predict = neural_network(X)
    cost_func = tf.reduce_mean(tf.square(predict -  Y))
    optimizer = tf.train.AdamOptimizer(0.001).minimize(cost_func)

    epochs = 100

    with tf.Session() as session:
        init = tf.group(tf.global_variables_initializer(), tf.local_variables_initializer())
        session.run(init)
        epoch_loss = 0
        for epoch in range(epochs):
            #pr = session.run(predict , feed_dict={X:train_x , Y:train_y})
            # print(pr)
            _ , c = session.run([optimizer , cost_func] , feed_dict={X:train_x , Y:train_y})
            epoch_loss += c
            print(epoch , ':' , epoch_loss)
            epoch_loss = 0

        correct = tf.equal(neural_network(test_x) , test_y)
        accuracy = tf.reduce_mean(tf.cast(correct , 'float'))
        print("准确率：",accuracy.eval({X:test_x , Y:test_y}))
        saver.save(session, 'myModelC/model.ckpt',)

train_neural_network(X,Y)

