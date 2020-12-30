//
//    DiceeApp : File.swift by tymek on 29/12/2020 12:02.
//    Copyright ©tymek 2020. All rights reserved.

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    var diceArray = [SCNNode]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // 1. Define the shape
        // let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.001)
        let mars = SCNSphere(radius: 0.2)
        
        // 2. add texture
        let materialMars = SCNMaterial()
        materialMars.diffuse.contents = UIImage(named: "art.scnassets/mars.png")
        
        //3. Attach material to the object
        mars.materials = [materialMars]
        
        // 4. Create node - attach it to the position
        let nodeMars = SCNNode()
        nodeMars.position = SCNVector3(0, 0.2, -0.5)
        
        // 5. put the shape created in the space:
        nodeMars.geometry = mars
        
        // 6. Attach the  node to the scene
        sceneView.scene.rootNode.addChildNode(nodeMars)
        
        
        let jupiter = SCNSphere(radius: 0.2)
        let materialJupiter = SCNMaterial()
        materialJupiter.diffuse.contents = UIImage(named: "art.scnassets/jupiter.jpg")
        jupiter.materials = [materialJupiter]
        let nodeJupiter = SCNNode()
        nodeJupiter.position = SCNVector3(0.6, 0.1, -0.5)
        nodeJupiter.geometry = jupiter
        sceneView.scene.rootNode.addChildNode(nodeJupiter)
        
        // 7. Add highlights and shadows
        sceneView.autoenablesDefaultLighting = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let worldConfiguration = ARWorldTrackingConfiguration()
        //enable horizontal plane detection
        worldConfiguration.planeDetection = .horizontal
        
        if ARWorldTrackingConfiguration.isSupported {
            print("World tracking configuration supported: \(ARWorldTrackingConfiguration.isSupported)")
        } else {
            print("Sessionconfiguration supported: \(ARConfiguration.isSupported)")
        }
        
        // Run the view's session
        sceneView.session.run(worldConfiguration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    // MARK: - DICE rendering methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let hitresult = results.first {
                addDice(atLocation: hitresult)
            }
        }
    }
    
    func addDice (atLocation location: ARHitTestResult) {
        let diceScene = SCNScene(named: "art.scnassets/dice.scn")!
        if  let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            diceNode.position = SCNVector3(
                location.worldTransform.columns.3.x,
                location.worldTransform.columns.3.y + (diceNode.boundingSphere.radius * 3),
                location.worldTransform.columns.3.z)
            
            diceArray.append(diceNode)
            sceneView.scene.rootNode.addChildNode(diceNode)
        }
    }
    
    func rollAll () {
        if  !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    func roll (dice: SCNNode) {
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1 ) * (Float.pi/2)
        dice.runAction(
            SCNAction.rotateBy(x: CGFloat(randomX*5), y: 0, z: CGFloat(randomZ*5), duration: 0.5)
        )
    }
    
    @IBAction func rollAllButton(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    // MARK: - ARSceneViewDelegate Methods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // cast anchor to PlaneAnchor to get into it's properties (width/height)
            guard let planeAnchor = anchor as? ARPlaneAnchor  else {return}
            let planeNode = createPlane(withPlaneAnchor: planeAnchor)
            node.addChildNode(planeNode)
    }
    
    // MARK: - Plane rendering
    
    func createPlane (withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z )
        
        // position requires 3d geometry, while we have only 2d, which means we need to trasnform the position:
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0 )
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        return planeNode
    }
    
}
