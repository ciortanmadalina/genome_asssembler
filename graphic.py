import matplotlib.pyplot as plt

def plot_data(input_dict, title, x_desc, y_desc):
    fig = plt.figure()
    ax1 = fig.add_subplot(111)
    ax1.set_title(title)
    ax1.set_xlabel(x_desc)
    ax1.set_ylabel(y_desc)
    for key, value in input_dict.iteritems():
        ax1.plot(value[0],value[1], c='r', label=key)
    leg = ax1.legend()
    plt.show()

def parseReport(line):
    tokens = line.split()
    return tokens[6], tokens[8], tokens[10]

def getN50(line):
    tokens = line.split()
    return tokens[3]

def generate_input_files(input_file_name):
    input_file = open(input_file_name)
    output_file = open("output.txt", "w")
    prefix = ""
    for line in input_file:
        if "read:" in line:
            nextline = next(input_file)
            if "contigs:" in nextline:
                print line, nextline
                paired = "paired"
                if "Paired" not in line:
                    paired = "single"
                bp, depth, error = parseReport(line)
                n50 = getN50(nextline)
                output_file.write( prefix + paired + " " + bp + " " + depth + " " + error + " "+ n50)
                prefix = "\n"
    output_file.close()


def extract_data (file_name):
    with open(file_name) as f:
        data = f.read()
    data = data.split('\n')
    paired = [row.split(' ')[0] for row in data]
    bp = [row.split(' ')[1] for row in data]
    depth = [row.split(' ')[2] for row in data]
    error = [row.split(' ')[3] for row in data]
    n50 = [row.split(' ')[4] for row in data]
    return paired, bp, depth, error, n50

def plot_file (file_name):
    paired, bp, depth, error, n50 = extract_data(file_name)
    depth_dict = {}

    #create depth dictionary
    for i in range(len(paired)):
        key = paired[i] + bp[i] + "_err" + error[i]
        if key not in depth_dict.keys():
            depth_dict[key] = ([], [])
        depth_dict[key][0].append(depth[i])
        depth_dict[key][1].append(n50[i])
    #plot depth
    plot_data(depth_dict , "n50 by depth", "depth", "n50")

    #create error dictionary
    for i in range(len(paired)):
        key = paired[i] + bp[i] + "_depth" + depth[i]
        if key not in depth_dict.keys():
            depth_dict[key] = ([], [])
        depth_dict[key][0].append(error[i])
        depth_dict[key][1].append(n50[i])
    #plot error
    plot_data(depth_dict , "n50 by error", "error", "n50")


generate_input_files("report.txt")
#plot_file("output.txt")
